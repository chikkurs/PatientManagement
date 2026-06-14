from faker import Faker
import random
import mysql.connector
import os
import dotenv
import base64

dotenv.load_dotenv()

fake = Faker()


 

IMAGE_PATH = [
    "download.jpg",
    "download1.jpg",
    "download2.jpg",
    "images3.jpg",
  
    "images5.jpg",
    "images6.jpg",
    "images7.jpg",
    "images8.jpg",
    "images9.jpg",
    "images10.jpg",
]


IMAGE_BASE64_LIST = []
for image_path in IMAGE_PATH:
    with open(image_path, "rb") as img:
        IMAGE_BASE64_LIST.append(
            base64.b64encode(
                img.read()
            ).decode("utf-8")
        )

print("Image Base64 Length:", len(IMAGE_BASE64_LIST))



# Database connection
conn = mysql.connector.connect(
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME")
)

cursor = conn.cursor()

departments = [
    "Cardiology",
    "Neurology",
    "Orthopedics",
    "Dermatology",
    "ENT",
    "General Medicine",
]

doctors = [
    "Dr. John",
    "Dr. Smith",
    "Dr. David",
    "Dr. Thomas",
    "Dr. Rahul",
    "Dr. Priya",
]

sql = """
INSERT INTO patients
(
    name,
    email,
    phone,
    age,
    height,
    weight,
    doctor_name,
    department,
    image_base64
)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

TOTAL_RECORDS = 10000
BATCH_SIZE = 1000

records = []

for i in range(TOTAL_RECORDS):
    records.append(
        (
            fake.name(),
            f"patient{i}@example.com",
            f"9{i:09d}",
            random.randint(18, 80),
            round(random.uniform(145, 190), 2),
            round(random.uniform(45, 110), 2),
            random.choice(doctors),
            random.choice(departments),
            random.choice(IMAGE_BASE64_LIST),
        )
    )

print(f"Generated {len(records)} records")

for i in range(0, len(records), BATCH_SIZE):
    batch = records[i:i + BATCH_SIZE]

    cursor.executemany(sql, batch)
    conn.commit()

    print(
        f"Inserted {min(i + BATCH_SIZE, TOTAL_RECORDS)} "
        f"/ {TOTAL_RECORDS}"
    )

cursor.close()
conn.close()

print("Successfully inserted 10,000 patient records.")