import math
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, func

from models import Patient
from schemas import PatientCreate

from typing import Optional



async def create_patient(db: AsyncSession, data: PatientCreate) -> Patient:
    patient = Patient(
        name=data.name,
        email=data.email,
        phone=data.phone,
        age=data.age,
        height=data.height,
        weight=data.weight,
        doctor_name=data.doctor_name,
        department=data.department,
        image_base64=data.image_base64,
    )
    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    return patient


async def get_patients(db: AsyncSession, page: int, page_size: int = 10):
    offset = (page - 1) * page_size

    count_result = await db.execute(select(func.count()).select_from(Patient))
    total = count_result.scalar()

    result = await db.execute(select(Patient).offset(offset).limit(page_size))
    patients = result.scalars().all()

    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
        "patients": patients,
    }


async def search_patients(db: AsyncSession, query: str, page: int, page_size: int = 10):
    search = f"%{query}%"
    filters = or_(
        Patient.name.ilike(search),
        Patient.email.ilike(search),
        Patient.phone.ilike(search),
        Patient.doctor_name.ilike(search),
        Patient.department.ilike(search),
    )

    offset = (page - 1) * page_size

    count_result = await db.execute(select(func.count()).select_from(Patient).where(filters))
    total = count_result.scalar()

    result = await db.execute(select(Patient).where(filters).offset(offset).limit(page_size))
    patients = result.scalars().all()

    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
        "patients": patients,
    }

async def get_patient_by_id(db: AsyncSession, patient_id: int) -> Optional[Patient]:
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    return result.scalar_one_or_none()


async def email_exists(db: AsyncSession, email: str) -> bool:
    result = await db.execute(select(Patient.id).where(Patient.email == email))
    return result.scalar_one_or_none() is not None


async def phone_exists(db: AsyncSession, phone: str) -> bool:
    result = await db.execute(select(Patient.id).where(Patient.phone == phone))
    return result.scalar_one_or_none() is not None
