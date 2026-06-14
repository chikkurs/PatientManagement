from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Form, File, UploadFile
import base64

from database import get_db, init_db
from schemas import PatientCreate, PatientResponse, PaginatedPatients
import crud
from fastapi.middleware.cors import CORSMiddleware
import traceback
from fastapi.responses import JSONResponse



@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="Patient Management API",
    description="API for managing patient records with image support",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
    allow_methods=["*"],
    allow_headers=["*"],
)




@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),
            "traceback": traceback.format_exc()
        }
    )



# ──────────────────────────────────────────────
# POST /patients  — Create a new patient
# ──────────────────────────────────────────────


@app.post(
    "/patients",
    response_model=PatientResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_patient(
    name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(...),
    age: int = Form(...),
    height: float = Form(...),
    weight: float = Form(...),
    doctor_name: str = Form(...),
    department: str = Form(...),
    image: UploadFile = File(None),
    db: AsyncSession = Depends(get_db),
):
    if await crud.email_exists(db, email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A patient with email '{email}' already exists.",
        )

    if await crud.phone_exists(db, phone):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A patient with phone '{phone}' already exists.",
        )

    image_base64 = None

    if image:
        image_bytes = await image.read()
        image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    payload = PatientCreate(
        name=name,
        email=email,
        phone=phone,
        age=age,
        height=height,
        weight=weight,
        doctor_name=doctor_name,
        department=department,
        image_base64=image_base64,
    )

    patient = await crud.create_patient(db, payload)
    return patient


# ──────────────────────────────────────────────
# GET /patients  — Paginated list
# ──────────────────────────────────────────────
@app.get(
    "/patients",
    response_model=PaginatedPatients,
    summary="Get all patients (paginated, 10 per page)",
)
async def get_patients(
    page: int = Query(default=1, ge=1, description="Page number (starts at 1)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Fetch all patient records with pagination.

    - Returns **10 records per page**.
    - Use the `page` query param to navigate pages.
    """
    result = await crud.get_patients(db, page=page, page_size=10)
    return result


# ──────────────────────────────────────────────
# GET /patients/{id}  — Single patient
# ──────────────────────────────────────────────
@app.get(
    "/patients/{patient_id}",
    response_model=PatientResponse,
    summary="Get a single patient by ID",
)
async def get_patient(
    patient_id: int,
    db: AsyncSession = Depends(get_db),
):
    patient = await crud.get_patient_by_id(db, patient_id)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Patient with id {patient_id} not found.",
        )
    return patient


@app.get(
    "/patients/search/query",
    response_model=PaginatedPatients,
    summary="Search patients by name, email, phone, doctor, or department",
)
async def search_patients(
    q: str = Query(..., min_length=1, description="Search keyword"),
    page: int = Query(default=1, ge=1, description="Page number (starts at 1)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Search patients across the following fields:
    - name
    - email
    - phone
    - doctor_name
    - department

    Results are paginated (10 per page).
    """
    result = await crud.search_patients(db, query=q, page=page, page_size=10)
    return result

