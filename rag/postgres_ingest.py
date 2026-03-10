import os
import psycopg2
from typing import List, Dict

def ingest_postgres_schema():
    """Connect to Postgres and extract schema details as docs."""
    db_url = os.getenv("POSTGRES_URL")
    if not db_url:
        raise ValueError("POSTGRES_URL must be set in .env")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    cur.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
    """)
    tables = [row[0] for row in cur.fetchall()]
    docs = []
    for table in tables:
        cur.execute(f"""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = '{table}'
        """)
        columns = cur.fetchall()
        schema_text = f"Table: {table}\n" + "\n".join([f"- {col[0]}: {col[1]}, nullable={col[2]}" for col in columns])
        docs.append({
            "id": f"table_{table}",
            "content": schema_text,
            "source": "postgres"
        })
    cur.close()
    conn.close()
    return docs
