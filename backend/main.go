package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"

	"time_mind/db" // путь к модулю, поправь под свой
)

func main() {
	// Загружаем .env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Инициализация БД
	db.Init()

	app := fiber.New()

	// Роут для списка пользователей
	app.Get("/users", func(c *fiber.Ctx) error {
		rows, err := db.Pool.Query(c.Context(), "SELECT id, username, email FROM \"user\" WHERE deleted_at IS NULL")
		if err != nil {
			return c.Status(500).SendString(err.Error())
		}
		defer rows.Close()

		var users []map[string]interface{}
		for rows.Next() {
			var id int
			var username, email string
			err := rows.Scan(&id, &username, &email)
			if err != nil {
				return err
			}
			users = append(users, map[string]interface{}{
				"id":       id,
				"username": username,
				"email":    email,
			})
		}

		return c.JSON(users)
	})
	app.Post("/users", func(c *fiber.Ctx) error {
		type User struct {
			Username string `json:"username"`
			Email    string `json:"email"`
		}
		var user User
		if err := c.BodyParser(&user); err != nil {
			return c.Status(400).SendString("Invalid request body")
		}
		_, err := db.Pool.Exec(c.Context(),
			`INSERT INTO "user" (username, email) VALUES ($1, $2)`,
			user.Username, user.Email)
		if err != nil {
			return c.Status(500).SendString(err.Error())
		}
		return c.Status(201).JSON(user)
	})

	// Получить пользователя по ID
	app.Get("/users/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		var username, email string
		err := db.Pool.QueryRow(c.Context(),
			`SELECT username, email FROM "user" WHERE id = $1`, id).Scan(&username, &email)
		if err != nil {
			return c.Status(404).SendString("User not found")
		}
		return c.JSON(fiber.Map{
			"id":       id,
			"username": username,
			"email":    email,
		})
	})

	// Обновить пользователя
	app.Put("/users/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		var user struct {
			Username string `json:"username"`
			Email    string `json:"email"`
		}
		if err := c.BodyParser(&user); err != nil {
			return c.Status(400).SendString("Invalid request body")
		}
		commandTag, err := db.Pool.Exec(c.Context(),
			`UPDATE "user" SET username=$1, email=$2 WHERE id=$3`,
			user.Username, user.Email, id)
		if err != nil {
			return c.Status(500).SendString(err.Error())
		}
		if commandTag.RowsAffected() == 0 {
			return c.Status(404).SendString("User not found")
		}
		return c.JSON(fiber.Map{"updated": id})
	})

	// Удалить пользователя
	app.Delete("/users/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		commandTag, err := db.Pool.Exec(c.Context(),
			`DELETE FROM "user" WHERE id=$1`, id)
		if err != nil {
			return c.Status(500).SendString(err.Error())
		}
		if commandTag.RowsAffected() == 0 {
			return c.Status(404).SendString("User not found")
		}
		return c.SendStatus(204)
	})

	// Запуск сервера на порту из .env или 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
	log.Fatal(app.Listen(":" + port))
}
