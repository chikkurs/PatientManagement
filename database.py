from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
import os
import dotenv

dotenv.load_dotenv()

# ─── Monkeypatch for SQLAlchemy pool_pre_ping TypeError ──────────────────────
# SQLAlchemy's pymysql dialect calls dbapi_connection.ping() with no arguments,
# but the aiomysql wrapper (AsyncAdapt_aiomysql_connection) expects a 'reconnect'
# positional argument. This monkeypatch makes it optional to prevent TypeErrors.
from sqlalchemy.dialects.mysql.aiomysql import AsyncAdapt_aiomysql_connection
_orig_ping = AsyncAdapt_aiomysql_connection.ping
def _patched_ping(self, reconnect=True):
    return _orig_ping(self, reconnect)
AsyncAdapt_aiomysql_connection.ping = _patched_ping
# ─────────────────────────────────────────────────────────────────────────────

# ─── MySQL connection settings ───────────────────────────────────────────────

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

DATABASE_URL = (
    f"mysql+aiomysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)
# ─────────────────────────────────────────────────────────────────────────────

engine = create_async_engine(
    DATABASE_URL,
    echo=True,
    pool_pre_ping=True,       # drops stale connections automatically
    pool_recycle=1800,        # recycle connections every 30 min
)

AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
