import zipfile
import sqlite3
import os

apkg_path = r"C:\Users\sealep\StudioProjects\ingles_1000-main\(3) NEY VASCONCELLOS - 1.000 Frases mais comuns em Inglês-20260310220334.apkg"

print(f"Lendo {apkg_path}")

with zipfile.ZipFile(apkg_path, 'r') as z:
    for filename in ['collection.anki2', 'collection.anki21b', 'collection.anki21']:
        if filename in z.namelist():
            print(f"Extraindo {filename}...")
            z.extract(filename, path=".")
            
            # Tentar abrir e ler
            try:
                conn = sqlite3.connect(filename)
                cursor = conn.cursor()
                
                # Checar tabelas
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
                tables = cursor.fetchall()
                print(f"Tabelas em {filename}: {[t[0] for t in tables]}")
                
                if ('notes',) in tables:
                    cursor.execute("SELECT count(*) FROM notes;")
                    print(f"Notes: {cursor.fetchone()[0]}")
                    
                if ('cards',) in tables:
                    cursor.execute("SELECT count(*) FROM cards;")
                    print(f"Cards: {cursor.fetchone()[0]}")
                    
                conn.close()
            except Exception as e:
                print(f"Erro ao ler {filename}: {e}")
            print("-" * 40)
