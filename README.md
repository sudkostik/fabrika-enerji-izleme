# fabrika enerji izleme projesi

Bu proje, bir fabrikanın ana giriş ve alt çıkış sayaçlarına ait enerji tüketim verilerinin SQL Server üzerinde oluşturulması, işlenmesi ve Grafana ile görselleştirilmesi amacıyla hazırlanmıştır.

## projenin amacı

Kümülatif elektrik sayacı endekslerinden günlük enerji tüketimini hesaplamak ve elde edilen verileri bir Grafana dashboard'u üzerinden analiz etmektir.

## kullanılan teknolojiler

- macOS
- Docker
- Microsoft SQL Server
- DBeaver
- Grafana
- SQL

## veri akışı

```text
Docker
   ↓
Microsoft SQL Server
   ↓
dbo.SayacVerileri
   ↓
dbo.vw_GunlukTuketim
   ↓
Grafana Dashboard
