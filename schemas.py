# pyrefly: ignore [missing-import]
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional


class PatientCreate(BaseModel):
    name: str
    email: EmailStr
    phone: str
    age: int
    height: float   # in cm
    weight: float   # in kg
    doctor_name: str
    department: str
    image_base64: Optional[str] = None  # base64 string (e.g. "data:image/jpeg;base64,...")

    @field_validator("age")
    @classmethod
    def age_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("Age must be a positive integer")
        return v

    @field_validator("height", "weight")
    @classmethod
    def must_be_positive(cls, v):
        if v <= 0:
            raise ValueError("Height and weight must be positive values")
        return v

    @field_validator("phone")
    @classmethod
    def phone_must_be_valid(cls, v):
        digits = v.replace("+", "").replace("-", "").replace(" ", "")
        if not digits.isdigit() or len(digits) < 7:
            raise ValueError("Phone number must contain at least 7 digits")
        return v


class PatientResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    age: int
    height: float
    weight: float
    doctor_name: str
    department: str
    image_base64: Optional[str] = None

    model_config = {"from_attributes": True}


class PaginatedPatients(BaseModel):
    total: int
    page: int
    page_size: int
    total_pages: int
    patients: list[PatientResponse]
