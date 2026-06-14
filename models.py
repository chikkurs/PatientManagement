from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.dialects.mysql import LONGTEXT
from database import Base


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    age = Column(Integer, nullable=False)
    height = Column(Float, nullable=False)   
    weight = Column(Float, nullable=False)   
    doctor_name = Column(String(100), nullable=False)
    department = Column(String(100), nullable=False)
    image_base64 = Column(LONGTEXT, nullable=True) 
