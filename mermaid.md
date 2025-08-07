# 🧠 Proje: Sanal Makine Yönetim Sistemi

Aşağıda sistemin tüm yapısı, süreçleri ve veri ilişkileri Mermaid diyagramları ile anlatılmıştır.

---

## 🧱 1. Sistem Mimarisi

```mermaid
graph TD
    UI[UI_Web_Arayuz] --> API[API_Sunucu]
    API --> DB[Veritabani]
    API --> VMManager[VM_Yoneticisi]
    VMManager --> VM1[Sanal_Makine_1]
    VMManager --> VM2[Sanal_Makine_2]
    VMManager --> Logger[Loglama_Servisi]
    VMManager --> Monitor[Izleme_Servisi]
```

---

## 🔁 2. Kullanıcı VM Oluşturma Süreci

```mermaid
sequenceDiagram
    participant Kullanıcı
    participant UI
    participant API
    participant VMManager
    participant Veritabanı

    Kullanıcı->>UI: "Yeni VM oluştur" isteği
    UI->>API: API çağrısı
    API->>Veritabanı: VM kaydı oluştur
    API->>VMManager: Yeni VM oluştur
    VMManager-->>API: VM başarıyla oluşturuldu
    API-->>UI: Başarılı yanıt
    UI-->>Kullanıcı: VM hazır bildirimi
```

---

## 📊 3. Sanal Makine Durumları

```mermaid
stateDiagram-v2
    [*] --> Hazır
    Hazır --> Çalışıyor : Başlat
    Çalışıyor --> Durdurulmuş : Durdur
    Durdurulmuş --> Çalışıyor : Devam Et
    Çalışıyor --> Silindi : Sil
    Durdurulmuş --> Silindi : Sil
```

---

## 🗃️ 4. Veritabanı Varlık İlişkileri (ER Diagram)

```mermaid
erDiagram
    KULLANICI ||--o{ VM : sahip
    VM ||--|{ KAYNAK : kullanır

    KULLANICI {
        int id
        string isim
        string email
        string rol
    }

    VM {
        int id
        string isim
        string durum
        int kullanici_id
    }

    KAYNAK {
        int id
        string tur
        string deger
        int vm_id
    }
```

---

## 🛠️ 5. Geliştirme Takvimi (Gantt Chart)

```mermaid
gantt
    title Geliştirme Planı
    dateFormat  YYYY-MM-DD
    section Tasarım
    Mimari Planlama       :a1, 2025-08-01, 4d
    UI/UX Tasarımı         :a2, after a1, 3d
    section Backend
    API Geliştirme         :b1, 2025-08-08, 6d
    VM Yönetimi            :b2, after b1, 5d
    section Entegrasyon
    Veritabanı Bağlantısı  :c1, 2025-08-17, 3d
    Loglama & İzleme       :c2, after c1, 3d
    section Test
    Test Süreci            :d1, 2025-08-21, 4d
    section Yayın
    Yayın Hazırlığı        :e1, 2025-08-25, 2d
```

---

## 🔁 6. Git Dal Yönetimi (Opsiyonel)

```mermaid
gitGraph
    commit
    branch feature/api
    commit
    branch feature/vm-control
    checkout main
    merge feature/api
    merge feature/vm-control
    commit
```

---

> Bu diyagramlar proje dokümantasyonu için idealdir. GitHub Markdown içinde doğrudan çalışır. Daha iyi önizleme için `https://mermaid.live` üzerinden test edebilirsin.
