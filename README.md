# Materializēto skatu atjaunošanas risinājums

## Apraksts  
Šis risinājums nodrošina materializēto skatu secīgu atjaunošanu ar atkarību pārvaldību un statusu izsekošanu.  
Tiek izmantotas šādas galvenās tabulas un procedūras:

- **mview_refresh_queue** – materializēto skatu atjaunošanas rinda ar statusiem un prioritātēm  
- **mview_dependency_map** – atkarību kartējums starp skatiem  
- **mview_refresh_log** – atjaunošanas žurnāls, kurā tiek reģistrēti notikumu laiki, statusi un kļūdu ziņojumi
- **set_mview_refresh_queue_ready** – procedūra, kas iestata visu rindas ierakstu statusu uz `ready`, gatavojot tos atjaunošanai
- **run_mview_refresh_queue** – procedūra, kas secīgi apstrādā rindas ierakstus, ievērojot atkarības un atjauno skatus
- **update_status** – procedūra, kas atjaunina statusu rindā un vienlaikus saglabā reģistru logā (ar kļūdu apstrādi)

## Procedūra run_mview_refresh_queue

### Apraksts  
Procedūra nodrošina materializēto skatu (materialized views) secīgu atjaunošanu, izmantojot rindu gaidīšanas tabulu `mview_refresh_queue`.  
Tā atlasa materializēto skatu ar statusu `ready`, pārbauda atkarības, maina statusu uz `in progress`, veic atjaunošanu, reģistrē procesu un maina statusu uz `done` vai `error` atkarībā no rezultāta.

### Procedūras galvenie soļi  
- Atlasa materializēto skatu ar statusu `ready` un bez neatjaunotām atkarībām  
- Maina statusu uz `in progress`  
- Izsauc (komentāros atstāts) `dbms_mview.refresh` materializētā skata atjaunošanai  
- Dzēš un izveido indeksus (izmantojot pagaidu funkcijas)  
- Veic darbību reģistrāciju tabulā `mview_refresh_log`  
- Maina statusu rindā uz `done` vai `error`  

### Svarīgi  
- `dbms_mview.refresh` izsaukums ir komentētā veidā un jāieslēdz ražošanas vidē  
- Funkcijas `drop_indexes`, `create_indexes`, `save_refresh_trace` pašlaik ir pagaidu aizvietotāji, kurus vajadzības gadījumā var aizstāt ar pilnvērtīgām realizācijām  
- Procedūra darbojas cikliski, līdz rindā vairs nav materializēto skatu, kas jāatjauno
- Procedūru `set_mview_refresh_queue_ready` ir jāizsauc katru reizi pirms `run_mview_refresh_queue` palaišanas, lai sagatavotu atjaunošanas rindu

### Testēšanas dati
Projektā ir iekļauts fails `data.sql`, kurā atrodami testa dati tabulām `mview_refresh_queue` un `mview_dependency_map`.  
Šie dati balstās uz reālajiem vai piemēra datiem no `existing.sql` un ir paredzēti, lai pārbaudītu materializēto skatu atjaunošanas loģiku un atkarību apstrādi.
Lai veiktu testa palaišanu, vispirms ielādējiet `data.sql` datubāzē.

### Piemērs izsaukumam  
```sql
BEGIN
    run_mview_refresh_queue;
END;
```

## Tabulu struktūra
```sql
CREATE TABLE mview_refresh_queue (
    mview_name VARCHAR2(128) PRIMARY KEY,
    status VARCHAR2(30),
    priority NUMBER
);

CREATE TABLE mview_dependency_map (
    mview_name VARCHAR2(128),
    depends_on VARCHAR2(128)
);

CREATE TABLE mview_refresh_log (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    mview_name VARCHAR2(128),
    status VARCHAR2(30),
    message VARCHAR2(4000),
    log_time DATE DEFAULT SYSDATE
);
```
