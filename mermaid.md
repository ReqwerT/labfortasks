```mermaid
flowchart TD
    A[Başlangıç] --> B{Karar Noktası}
    B -- Evet --> C[İşlem 1]
    B -- Hayır --> D[İşlem 2]
    C --> E[Son]
    D --> E
