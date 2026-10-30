up:
	docker compose up -d --build

tunnel:
	docker compose --profile tunnel up -d --build

down:
	docker compose down

logs:
	docker compose logs -f web

test:
	docker compose exec web pytest

lint:
	docker compose exec web ruff check .
	docker compose exec web ruff format --check .

makemigrations:
	docker compose exec web python manage.py makemigrations

createsuperuser:
	docker compose exec web python manage.py createsuperuser

.PHONY: up tunnel down logs test lint makemigrations createsuperuser
