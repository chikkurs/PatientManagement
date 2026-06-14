# Patient Management API

FastAPI backend for managing patient records with base64 image support, using **MySQL**.

## Setup

### 1. Create the MySQL database

```sql
CREATE DATABASE patient_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Configure credentials

Edit `database.py` and set your values:

```python
DB_USER     = "root"
DB_PASSWORD = "your_password"
DB_HOST     = "localhost"
DB_PORT     = 3306
DB_NAME     = "patient_db"
```

### 3. Install dependencies & run

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

Swagger docs: http://127.0.0.1:8000/docs

---

## API Endpoints

### POST /patients — Create patient

```json
{
  "name": "Arun Kumar",
  "email": "arun@example.com",
  "phone": "+919876543210",
  "age": 35,
  "height": 175.5,
  "weight": 70.0,
  "doctor_name": "Dr. Priya Nair",
  "department": "Cardiology",
  "image_base64": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

- `409` if email or phone already exists
- `422` on validation error

### GET /patients?page=1 — All patients (10 per page)

```json
{
  "total": 45,
  "page": 1,
  "page_size": 10,
  "total_pages": 5,
  "patients": [ ... ]
}
```

### GET /patients/{id} — Single patient

### GET /patients/search/query?q=cardiology&page=1 — Search

Searches across: name, email, phone, doctor_name, department.

---

## Notes

- Image stored as **LONGTEXT** in MySQL (handles images up to ~4GB).
- Height in **cm**, weight in **kg**.
- Email and phone are unique at both DB and application level.
- `pool_pre_ping=True` handles dropped MySQL connections gracefully.
