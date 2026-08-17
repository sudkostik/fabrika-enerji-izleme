#!/bin/bash
set -e

echo "=========================================="
echo "SQL Server Veritabani Baslatma Scripti"
echo "=========================================="

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -f "$SQLCMD" ]; then
    SQLCMD="/opt/mssql-tools/bin/sqlcmd"
fi

SA_PASSWORD=${MSSQL_SA_PASSWORD:-"SqlServer2026!"}
DB_NAME="TestDB"

echo "1) TestDB veritabani kontrol ediliyor / olusturuluyor..."
$SQLCMD -S sqlserver -U sa -P "$SA_PASSWORD" -C -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$DB_NAME') CREATE DATABASE [$DB_NAME];"

echo "2) 01_generate_sample_meter_data.sql calistiriliyor (Sayac verileri uretiliyor)..."
$SQLCMD -S sqlserver -U sa -P "$SA_PASSWORD" -C -d "$DB_NAME" -i /init-scripts/01_generate_sample_meter_data.sql

echo "3) 02_create_energy_consumption_views.sql calistiriliyor (View'lar olusturuluyor)..."
$SQLCMD -S sqlserver -U sa -P "$SA_PASSWORD" -C -d "$DB_NAME" -i /init-scripts/02_create_energy_consumption_views.sql

echo "=========================================="
echo " Veritabani basariyla hazirlandi!"
echo "=========================================="
