#  Fabrika Enerji İzleme ve Yönetim Sistemi

Bu proje, bir endüstriyel tesisin (fabrika) ana giriş ve alt çıkış elektrik sayaçlarına ait enerji tüketim verilerinin **Microsoft SQL Server** üzerinde modellenmesi, analitik görünümlerle (SQL Views) işlenmesi ve **Grafana** üzerinde interaktif panellerle görselleştirilmesi amacıyla geliştirilmiştir.

---

##  Projenin Amacı ve Kapsamı

- **Kümülatif Endeks Yönetimi:** Saatlik kümülatif sayaç endekslerinden günlük net tüketimlerin (`kWh`) hesaplanması.
- **Giriş / Çıkış Tutarlılık Analizi:** Ana giriş sayacı ile alt birimlerin (Dökümhane, Kompresörler, CNC, Chiller vb.) tüketimlerinin karşılaştırılması.
- **Otomatik Altyapı:** Docker Compose ve Grafana Provisioning ile tek komutla, sıfır konfigürasyonla çalışan ortam.

---

##  Veri ve Sistem Mimarisi

```text
               ┌────────────────────────────────────────────────────────┐
               │              Docker Compose Altyapısı                  │
               │                                                        │
               │  ┌──────────────────────┐    ┌──────────────────────┐  │
               │  │      SQL Server      │    │       Grafana        │  │
               │  │  (TestDB Veritabanı) │    │  (Auto-Provisioning) │  │
               │  └──────────┬───────────┘    └──────────▲───────────┘  │
               │             │                           │              │
               │             ▼                           │              │
               │     dbo.SayacVerileri                   │              │
               │             │                           │              │
               │             ▼                           │              │
               │    dbo.vw_GunlukTuketim ────────────────┘              │
               │   dbo.vw_GunlukTuketim_Kesin                           │
               └────────────────────────────────────────────────────────┘
```

---

##  Hızlı Başlangıç (Tek Komutla Çalıştırma)

Projeyi bilgisayarınızda çalıştırmak için yalnızca Docker'ın yüklü olması yeterlidir.

### 1. Depoyu Klonlayın
```bash
git clone https://github.com/sudkostik/fabrika-enerji-izleme.git
cd fabrika-enerji-izleme
```

### 2. Docker Compose ile Başlatın
```bash
docker compose up -d
```

> **Not:** Arka planda SQL Server ayağa kalkar, tablolar ve view'lar otomatik oluşturulur, örnek sayaç verileri yüklenir ve Grafana veri kaynağı ile dashboard otomatik olarak bağlanır.

### 3. Grafana'yı Açın
Tarayıcınızdan aşağıdaki adrese gidin:
- **URL:** [http://localhost:3000](http://localhost:3000)
- **Kullanıcı Adı:** `admin` *(Anonim giriş aktiftir, şifresiz de açılır)*
- **Şifre:** `admin`

---

##  Grafana Dashboard Panelleri

Dashboard içinde aşağıdaki analiz ve metrik panelleri yer almaktadır:

1. **Ana Giriş Toplam Tüketim:** Fabrikanın seçilen dönemdeki toplam aktif enerji tüketimi.
2. **Çıkışlar Toplam Tüketim:** Tüm alt makinelerin toplam tüketimi.
3. **Ortalama Günlük Tüketim:** Tesisin günlük ortalama baz yükü.
4. **En Çok Tüketen Çıkış:** En yüksek enerji çeken departman / makine.
5. **Günlük Tüketim Trendi:** Zaman serisi üzerinde günlük tüketim dağılımı.
6. **Çıkışlara Göre Dağılım:** Pasta grafiği ile departman bazlı enerji yüzdeleri.
7. **Çıkışlara Göre Toplam Tüketim:** Çubuk (Bar) grafiğiyle makine kıyaslamaları.
8. **Günlük Tüketim Detayı:** Tarih ve sayaç bazında detaylı veri tablosu.
9. **Toplam Karbon Salımı ($tCO_2$):** Elektrik tüketimine bağlı oluşan sera gazı emisyonu (ESG KPI'ı).
10. **Saatlik Tüketim Isı Haritası (Heatmap):** Günün 24 saati boyunca çekilen gücün saatlik yoğunluk matrisi.

---

##  SQL Yapısı ve Görünümler

### Tablo: `dbo.SayacVerileri`
| Sütun Adı | Veri Tipi | Açıklama |
|---|---|---|
| `Id` | INT (Identity) | Benzersiz kayıt numarası |
| `DateTime` | DATETIME | Saatlik ölçüm zaman damgası |
| `Type` | NVARCHAR(3) | `'In'` (Giriş) veya `'Out'` (Çıkış) |
| `Name` | NVARCHAR(50) | Sayaç / Makine adı |
| `Index` | DECIMAL(18,2) | Kümülatif endeks değeri (kWh) |

### Görünüm: `dbo.vw_GunlukTuketim`
Günlük bazda minimum ve maksimum endeks farkını alarak tüketimi hesaplar:
$$\text{Günlük Tüketim} = \text{MAX}(Endeks) - \text{MIN}(Endeks)$$

### Görünüm: `dbo.vw_GunlukTuketim_Kesin`
Gün geçişlerindeki (23:00 - 00:00) saat sınır hassasiyetini korumak için `LAG()` pencere fonksiyonuyla bir önceki günün son endeksini baz alır.

---

##  Manuel Kurulum (Docker Olmadan)

Eğer mevcut bir SQL Server örneğiniz varsa:

1. SQL Server üzerinde `TestDB` adında bir veritabanı oluşturun.
2. [01_generate_sample_meter_data.sql](01_generate_sample_meter_data.sql) scriptini çalıştırarak örnek verileri üretin.
3. [02_create_energy_consumption_views.sql](02_create_energy_consumption_views.sql) scriptini çalıştırarak analitik görünümleri oluşturun.
4. Grafana arayüzünden **Dashboards > Import** seçeneğine giderek [grafana_energy_dashboard.json](grafana_energy_dashboard.json) dosyasını içe aktarın.

---

##  Kullanılan Teknolojiler

- **Veritabanı:** Microsoft SQL Server 2022
- **Görselleştirme & Dashboard:** Grafana (v11+)
- **Konteynerleştirme:** Docker & Docker Compose
- **Sorgulama:** T-SQL (Window Functions, CTEs, Aggregations)
