import asyncpg
import logging
from typing import Optional
from ..config import settings

logger = logging.getLogger(__name__)

# Global database connection pool
_pool: Optional[asyncpg.Pool] = None

async def init_db():
    """Initialize database connection pool"""
    global _pool
    try:
        _pool = await asyncpg.create_pool(
            settings.database_url,
            min_size=5,
            max_size=20,
            command_timeout=60
        )
        logger.info("Database connection pool initialized")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise

async def close_db():
    """Close database connection pool"""
    global _pool
    if _pool:
        await _pool.close()
        logger.info("Database connection pool closed")

async def get_db():
    """Get database connection from pool"""
    if not _pool:
        raise RuntimeError("Database not initialized")
    return _pool

async def execute_query(query: str, *args):
    """Execute a database query"""
    async with _pool.acquire() as conn:
        return await conn.execute(query, *args)

async def fetch_one(query: str, *args):
    """Fetch a single row from database"""
    async with _pool.acquire() as conn:
        return await conn.fetchrow(query, *args)

async def fetch_all(query: str, *args):
    """Fetch all rows from database"""
    async with _pool.acquire() as conn:
        return await conn.fetch(query, *args) 