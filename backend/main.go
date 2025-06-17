package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=disable",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)

	conn, err := pgx.Connect(context.Background(), dsn)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer conn.Close(context.Background())

	// Проверка соединения
	if err := conn.Ping(context.Background()); err != nil {
		log.Fatalf("Cannot ping database: %v\n", err)
	}
	log.Println("✅ Successfully connected to the database!")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "TTimeMind Backend is alive and kicking!")
	})

	log.Println("🚀 Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
	log.Printf("Connecting to DB with DSN: %s", dsn)

}

// import (
// 	"context"
// 	"log"
// 	"net/http"

// 	"github.com/gin-gonic/gin"
// 	"github.com/jackc/pgx/v5"
// 	"os"
// )

// func main() {
// 	// Подключение к БД
// 	dsn := "postgres://postgres:Bazar%20sada15082005@localhost:5432/time_mind_db?sslmode=disable"

// 	conn, err := pgx.Connect(context.Background(), dsn)
// 	if err != nil {
// 		log.Fatalf("Unable to connect to database: %v\n", err)
// 	}
// 	defer conn.Close(context.Background())

// 	// Проверка соединения
// 	err = conn.Ping(context.Background())
// 	if err != nil {
// 		log.Fatalf("Cannot ping database: %v\n", err)
// 	}
// 	log.Println("✅ Successfully connected to the database!")

// 	// HTTP-сервер
// 	r := gin.Default()

// 	r.GET("/health", func(c *gin.Context) {
// 		c.JSON(http.StatusOK, gin.H{"status": "ok"})
// 	})

// 	r.Run(":8080")
// }
