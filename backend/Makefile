build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

shell:
	docker-compose exec web sh

makemigrations:
	docker-compose exec web python manage.py makemigrations

migrate:
	docker-compose exec web python manage.py migrate

createsuperuser:
	docker-compose exec web python manage.py createsuperuser

test:
	docker-compose exec web python manage.py test

django_shell:
	docker-compose exec web python manage.py shell