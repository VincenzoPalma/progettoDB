CREATE TABLE IF NOT EXISTS autore
(
    idautore SERIAL NOT NULL,
    nominativo varchar(50) NOT NULL,
    datanascita date,
    istituto varchar(100),
    CONSTRAINT autorepk PRIMARY KEY (idautore)
);

CREATE TABLE IF NOT EXISTS rivista
(
    issn char(9) NOT NULL,
    nome varchar(32) NOT NULL,
    numero int NOT NULL,
    tema varchar(20) NOT NULL,
    annopubblicazione int NOT NULL,
    responsabile varchar(50) NOT NULL,
    CONSTRAINT rivistapk PRIMARY KEY (issn, numero),
    CONSTRAINT formato_issn CHECK ( issn LIKE '____-____' )
);

CREATE TABLE IF NOT EXISTS conferenza
(
    idconferenza SERIAL NOT NULL,
    citta varchar(32) NOT NULL,
    struttura varchar(50) NOT NULL,
    datainizio date NOT NULL,
    datafine date,
    responsabile varchar(50) NOT NULL,
    CONSTRAINT conferenzapk PRIMARY KEY (idconferenza),
    CONSTRAINT ordinedata_conferenza CHECK ( datainizio <= datafine )
);

CREATE TABLE IF NOT EXISTS articoloscientifico
(
    idarticolo SERIAL NOT NULL,
    titolo varchar(100) NOT NULL,
    tema varchar(30) NOT NULL,
    argomento varchar(50) NOT NULL,
    annopubblicazione int NOT NULL,
    editore varchar(50) NOT NULL,
    cartaceo boolean NOT NULL,
    digitale boolean NOT NULL,
    audiolibro boolean NOT NULL,
    issn_rivista char(9),
    numero_rivista int,
    idconferenza int,
    CONSTRAINT articolopk PRIMARY KEY (idarticolo),
    CONSTRAINT rivistafk FOREIGN KEY (issn_rivista, numero_rivista) REFERENCES rivista (issn, numero)
    ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT conferenzafk FOREIGN KEY (idconferenza) REFERENCES conferenza (idconferenza)
    ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT formato CHECK ( cartaceo = true OR digitale = true ),
    CONSTRAINT check_pubblicazione CHECK ( idconferenza IS NOT NULL OR issn_rivista IS NOT NULL AND numero_rivista IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS rel_autore_articolo
(
    idautore int NOT NULL,
    idarticolo int NOT NULL,
    CONSTRAINT autore_articolofk FOREIGN KEY (idarticolo) REFERENCES articoloscientifico(idarticolo)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT articolo_autorefk FOREIGN KEY (idautore) REFERENCES autore(idautore)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT autore_articolo_unico UNIQUE (idautore, idarticolo)
);

CREATE TABLE IF NOT EXISTS serie
(
    idserie SERIAL NOT NULL,
    titolo varchar(50) NOT NULL,
    CONSTRAINT seriepk PRIMARY KEY (idserie)
);

CREATE TABLE IF NOT EXISTS libro
(
    isbn char(13) NOT NULL,
    titolo varchar(100) NOT NULL,
    genere varchar(50) NOT NULL,
    datauscita date,
    tipo varchar(9) NOT NULL,
    editore varchar(50) NOT NULL,
    cartaceo boolean NOT NULL,
    digitale boolean NOT NULL,
    audiolibro boolean NOT NULL,
    seguito char(13),
    CONSTRAINT libropk PRIMARY KEY (isbn),
    CONSTRAINT seguitofk FOREIGN KEY (seguito) REFERENCES libro(isbn)
    ON DELETE SET NULL ON UPDATE CASCADE ,
    CONSTRAINT seguitounico UNIQUE (seguito),
    CONSTRAINT formato CHECK ( cartaceo = true OR digitale = true ),
    CONSTRAINT tipo_libro CHECK ( (tipo = 'Romanzo') OR (tipo = 'Didattico' AND seguito IS NULL) ),
    CONSTRAINT checkseguito CHECK ( isbn != seguito )
);

CREATE TABLE IF NOT EXISTS rel_libro_serie
(
    isbn char(13) NOT NULL,
    idserie int NOT NULL,
    CONSTRAINT serie_librofk FOREIGN KEY (isbn) REFERENCES libro (isbn)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT libro_seriefk FOREIGN KEY (idserie) REFERENCES serie (idserie)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT serielibropk PRIMARY KEY (isbn)
);

CREATE TABLE IF NOT EXISTS utente
(
    username varchar(30) NOT NULL,
    password varchar(30) NOT NULL,
    tipo varchar NOT NULL,
    CONSTRAINT utentepk PRIMARY KEY (username),
    CONSTRAINT tipo_utente CHECK ( tipo = 'Utente' OR tipo = 'Amministratore' ),
    CONSTRAINT lunghezza_psw CHECK ( length(password) >= 5 )
);

CREATE TABLE IF NOT EXISTS notifica
(
    username varchar(30) NOT NULL,
    idserie int NOT NULL,
    data date NOT NULL,
    orario time NOT NULL,
    CONSTRAINT notifica_utentefk FOREIGN KEY (username) REFERENCES utente (username)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT notifica_seriefk FOREIGN KEY (idserie) REFERENCES serie (idserie)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT notificaunica UNIQUE (username, idserie)
);

CREATE TABLE IF NOT EXISTS rel_serie_utente
(
    username varchar(30) NOT NULL,
    idserie int NOT NULL,
    CONSTRAINT preferenza_utentefk FOREIGN KEY (username) REFERENCES utente (username)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT preferenza_seriefk FOREIGN KEY (idserie) REFERENCES serie (idserie)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT serie_utente_unica UNIQUE (username, idserie)
);

CREATE TABLE IF NOT EXISTS rel_autore_libro
(
    idautore int NOT NULL,
    isbn char(13) NOT NULL,
    CONSTRAINT autore_librofk FOREIGN KEY (isbn) REFERENCES libro (isbn)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT libro_autorefk FOREIGN KEY (idautore) REFERENCES autore (idautore)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT autore_libro_unico UNIQUE (isbn, idautore)
);

CREATE TABLE IF NOT EXISTS sala
(
    idsala SERIAL NOT NULL,
    nome varchar(30) NOT NULL,
    indirizzo varchar(50) NOT NULL,
    capienza int NOT NULL,
    CONSTRAINT salapk PRIMARY KEY (idsala)
);

CREATE TABLE IF NOT EXISTS rel_libro_sala
(
    isbn char(13) NOT NULL,
    idsala int NOT NULL,
    data date NOT NULL,
    CONSTRAINT sala_librofk FOREIGN KEY (isbn) REFERENCES libro (isbn)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT libro_salafk FOREIGN KEY (idsala) REFERENCES sala (idsala)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT libro_sala_data_unico UNIQUE (isbn, idsala, data)
);

CREATE TABLE IF NOT EXISTS collana
(
    issn char(9) NOT NULL,
    nome varchar(50) NOT NULL,
    caratteristica varchar(50) NOT NULL,
    descrizione varchar(200),
    datapubblicazione date NOT NULL,
    direttore varchar NOT NULL,
    editore varchar NOT NULL,
    CONSTRAINT collanapk PRIMARY KEY (issn),
    CONSTRAINT formato_issn CHECK ( issn LIKE '____-____' )
);

CREATE TABLE IF NOT EXISTS rel_libro_collana
(
    isbn char(13) NOT NULL,
    issn char(9) NOT NULL,
    data date NOT NULL,
    CONSTRAINT libro_collanafk FOREIGN KEY (issn) REFERENCES collana(issn)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT collana_librofk FOREIGN KEY (isbn) REFERENCES libro(isbn)
    ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT libro_collana_unico UNIQUE (isbn, issn)
);

CREATE TABLE IF NOT EXISTS negozio
(
    idnegozio SERIAL NOT NULL,
    nome varchar(30) NOT NULL,
    sito varchar(30),
    CONSTRAINT negoziopk PRIMARY KEY (idnegozio),
    CONSTRAINT formatsito CHECK ( sito IS NULL OR sito LIKE '%'||'.it' OR sito LIKE '%'||'.com' )
);

CREATE TABLE IF NOT EXISTS rel_libro_negozio
(
    isbn char(13) NOT NULL,
    prezzo numeric(8,2) NOT NULL,
    idnegozio int NOT NULL,
    CONSTRAINT negozio_librofk FOREIGN KEY (isbn) REFERENCES libro(isbn)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT libro_negoziofk FOREIGN KEY (idnegozio) REFERENCES negozio(idnegozio)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT prezzopositivo CHECK ( prezzo >= 0 ),
    CONSTRAINT disponibilitaunica UNIQUE (isbn, idnegozio)
);

CREATE TABLE IF NOT EXISTS puntovendita
(
    idpuntovendita SERIAL NOT NULL,
    nome varchar(30) NOT NULL,
    citta varchar(20) NOT NULL,
    idnegozio int NOT NULL,
    CONSTRAINT puntovenditapk PRIMARY KEY (idpuntovendita),
    CONSTRAINT negoziofk FOREIGN KEY (idnegozio) REFERENCES negozio (idnegozio)
    ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE OR REPLACE FUNCTION function_elimina_serie_vuota()
RETURNS trigger language plpgsql
as $$BEGIN
    IF (SELECT COUNT(*)
        FROM rel_libro_serie as r
        WHERE r.idserie = old.idserie) = 0
        THEN DELETE FROM serie WHERE idserie = old.idserie;
        END IF;
    RETURN NULL;
END; $$;

CREATE OR REPLACE TRIGGER elimina_serie_vuota AFTER DELETE OR UPDATE on rel_libro_serie
    FOR EACH ROW EXECUTE FUNCTION function_elimina_serie_vuota();


CREATE OR REPLACE FUNCTION function_elimina_collana_vuota()
RETURNS trigger LANGUAGE plpgsql
as $$BEGIN
    IF (SELECT COUNT(*)
        FROM rel_libro_collana as r
        WHERE r.issn = old.issn) = 0
        THEN DELETE FROM collana WHERE issn = old.issn;
        END IF;
    RETURN NULL;
END; $$;

CREATE OR REPLACE TRIGGER elimina_collana_vuota AFTER DELETE OR UPDATE on rel_libro_collana
    FOR EACH ROW EXECUTE FUNCTION function_elimina_collana_vuota();


CREATE OR REPLACE FUNCTION function_elimina_sala_inutilizzata()
RETURNS trigger language plpgsql
as $$BEGIN
    IF (SELECT COUNT(*)
        FROM rel_libro_sala as r
        WHERE r.idsala = old.idsala) = 0
        THEN DELETE FROM sala WHERE idsala = old.idsala;
        END IF;
    RETURN NULL;
END; $$;

CREATE OR REPLACE TRIGGER elimina_sala_inutilizzata AFTER DELETE OR UPDATE on rel_libro_sala
    FOR EACH ROW EXECUTE FUNCTION function_elimina_sala_inutilizzata();


CREATE OR REPLACE FUNCTION appartenenza_serie(isbn_libro libro.isbn%TYPE)
RETURNS integer language plpgsql
as $$ DECLARE appartenenza integer;
    BEGIN
    appartenenza = (SELECT COUNT(*)
                    FROM rel_libro_serie rls
                    WHERE rls.isbn = isbn_libro);
    RETURN appartenenza;
END;$$;


CREATE OR REPLACE FUNCTION cerca_idserie_da_isbn(isbnlibro libro.isbn%TYPE)
RETURNS integer LANGUAGE plpgsql
as $$
DECLARE serie serie.idserie%TYPE;
BEGIN
    IF appartenenza_serie(isbnlibro) = 0
    THEN RETURN NULL;
    END IF;
    SELECT idserie INTO serie
    FROM rel_libro_serie as rls
    WHERE rls.isbn = isbnlibro;
    RETURN serie;
END;$$;


CREATE OR REPLACE FUNCTION n_negozi_seriecompleta(serie serie.idserie%TYPE)
RETURNS integer  LANGUAGE plpgsql
as $$
    DECLARE n_negozi integer;
            n_libri_serie integer;
    BEGIN
    SELECT COUNT (*) INTO n_libri_serie
    FROM rel_libro_serie as rls
    WHERE rls.idserie = serie;
    IF n_libri_serie = 0
    THEN RETURN 0;
    END IF;

    SELECT COUNT(*) INTO n_negozi
    FROM negozio as n
    WHERE (SELECT COUNT(*)
           FROM rel_libro_negozio as rln JOIN libro l on l.isbn = rln.isbn JOIN rel_libro_serie rls on l.isbn = rls.isbn
           WHERE rln.idnegozio = n.idnegozio AND rls.idserie = serie) = n_libri_serie;
    RETURN n_negozi;
    END;$$;


CREATE OR REPLACE FUNCTION crea_notifica()
RETURNS trigger LANGUAGE plpgsql
as $$
    DECLARE serie rel_serie_utente.idserie %TYPE;
            usernametrovato utente.username %TYPE;
            username_preferenze CURSOR FOR
            SELECT rsu.username
            FROM rel_serie_utente as rsu
            WHERE rsu.idserie = serie;
    BEGIN
    serie = cerca_idserie_da_isbn(new.isbn);
    IF (serie) IS NULL
    THEN RETURN NULL;
    END IF;
    IF n_negozi_seriecompleta(serie) = 1
        THEN
        FOR usernametrovato IN username_preferenze LOOP
		IF (EXISTS(SELECT * FROM notifica WHERE idserie = serie AND username = usernametrovato.username)) = FALSE
        	THEN INSERT INTO notifica VALUES (usernametrovato.username, serie, CURRENT_DATE, CURRENT_TIME);
		END IF;
        END LOOP;
        END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER manda_notifica AFTER INSERT OR UPDATE ON rel_libro_negozio
    FOR EACH ROW EXECUTE FUNCTION crea_notifica();


CREATE OR REPLACE FUNCTION crea_notifica_preferenza()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
        IF n_negozi_seriecompleta(new.idserie) > 0
        THEN INSERT INTO notifica VALUES (new.username, new.idserie, CURRENT_DATE, CURRENT_TIME);
        END IF;
    RETURN NULL;
    END;
    $$;

CREATE OR REPLACE TRIGGER manda_notifica_preferenza AFTER INSERT OR UPDATE ON rel_serie_utente
    FOR EACH ROW EXECUTE FUNCTION crea_notifica_preferenza();


CREATE OR REPLACE FUNCTION controllo_disponibilita_completa()
RETURNS trigger LANGUAGE plpgsql
as $$
    DECLARE serie integer;
    BEGIN
    serie = cerca_idserie_da_isbn(old.isbn);
    IF (serie) IS NULL
    THEN RETURN NULL;
    END IF;
    IF n_negozi_seriecompleta(serie) = 0
        THEN DELETE FROM notifica WHERE idserie = serie;
        END IF;
        RETURN NULL;
    END; $$;

CREATE OR REPLACE TRIGGER elimina_notifica AFTER DELETE OR UPDATE on rel_libro_negozio
    FOR EACH ROW EXECUTE FUNCTION controllo_disponibilita_completa();


CREATE OR REPLACE FUNCTION function_elimina_notifica_preferenza()
RETURNS trigger LANGUAGE plpgsql
as $$
    BEGIN
    DELETE FROM notifica WHERE username = old.username AND idserie = old.idserie;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER elimina_notifica_preferenza AFTER DELETE OR UPDATE on rel_serie_utente
    FOR EACH ROW EXECUTE FUNCTION function_elimina_notifica_preferenza();


CREATE OR REPLACE FUNCTION function_accomuna_serie()
RETURNS trigger language plpgsql
as $$BEGIN
    IF (appartenenza_serie(new.isbn) = 1 AND appartenenza_serie(new.seguito) = 0)
    THEN INSERT INTO rel_libro_serie VALUES (new.seguito, cerca_idserie_da_isbn(new.isbn));
    ELSEIF (appartenenza_serie(new.isbn) = 0 AND appartenenza_serie(new.seguito) = 1)
    THEN INSERT INTO rel_libro_serie VALUES (new.isbn, cerca_idserie_da_isbn(new.seguito));
    END IF;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER accomuna_serie AFTER INSERT OR UPDATE OF seguito ON libro
    FOR EACH ROW WHEN ( new.seguito IS NOT NULL )
    EXECUTE FUNCTION function_accomuna_serie();


CREATE OR REPLACE FUNCTION elimina_negozio_senza_canali()
RETURNS trigger LANGUAGE plpgsql
as $$BEGIN
    IF (SELECT COUNT(*)
        FROM negozio as n JOIN puntovendita p on n.idnegozio = p.idnegozio
        WHERE n.idnegozio = old.idnegozio) = 0
    AND (SELECT n.sito
         FROM negozio as n
         WHERE n.idnegozio = old.idnegozio) IS NULL
    THEN DELETE FROM negozio WHERE idnegozio = old.idnegozio;
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER elimina_negozio_senza_puntivendita AFTER DELETE OR UPDATE ON puntovendita
    FOR EACH ROW EXECUTE FUNCTION elimina_negozio_senza_canali();

CREATE OR REPLACE TRIGGER elimina_negozio_sitonull AFTER UPDATE OF sito ON negozio
    FOR EACH ROW WHEN (new.sito IS NULL) EXECUTE FUNCTION elimina_negozio_senza_canali();


CREATE OR REPLACE FUNCTION function_cancella_canale_vuoto()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
        IF (SELECT COUNT(*)
        FROM articoloscientifico as a JOIN rivista r on r.issn = a.issn_rivista and r.numero = a.numero_rivista
        WHERE r.issn = old.issn_rivista AND r.numero = old.numero_rivista) = 0
        THEN DELETE FROM rivista WHERE issn = old.issn_rivista AND numero = old.numero_rivista;
        END IF;
        IF (SELECT COUNT(*)
        FROM articoloscientifico as a JOIN conferenza c on c.idconferenza = a.idconferenza
        WHERE c.idconferenza = old.idconferenza) = 0
        THEN DELETE FROM conferenza WHERE idconferenza = old.idconferenza;
        END IF;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER cancella_canale_vuoto AFTER DELETE OR UPDATE OF numero_rivista, issn_rivista, idconferenza ON articoloscientifico
    FOR EACH ROW EXECUTE FUNCTION function_cancella_canale_vuoto();


CREATE OR REPLACE FUNCTION function_crea_notifica_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$
    DECLARE usernametrovato utente.username %TYPE;
            username_preferenze CURSOR FOR
            SELECT rsu.username
            FROM rel_serie_utente as rsu
            WHERE rsu.idserie = old.idserie;
    BEGIN
    IF n_negozi_seriecompleta(old.idserie) > 0
        THEN
        FOR usernametrovato IN username_preferenze LOOP
		IF (EXISTS(SELECT * FROM notifica WHERE idserie = old.idserie AND username = usernametrovato.username)) = FALSE
        	THEN INSERT INTO notifica VALUES (usernametrovato.username, old.idserie, CURRENT_DATE, CURRENT_TIME);
		END IF;
        END LOOP;
    END IF;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER crea_notifica_libro AFTER DELETE OR UPDATE ON rel_libro_serie
    FOR EACH ROW EXECUTE FUNCTION function_crea_notifica_libro();


CREATE OR REPLACE FUNCTION function_elimina_notifica_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF n_negozi_seriecompleta(new.idserie) = 0
    THEN DELETE FROM notifica WHERE idserie = new.idserie;
    END IF;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER elimina_notifica_libro AFTER INSERT OR UPDATE ON rel_libro_serie
    FOR EACH ROW EXECUTE FUNCTION function_elimina_notifica_libro();


CREATE OR REPLACE FUNCTION controllo_editore_libro_collana()
RETURNS trigger LANGUAGE plpgsql
AS $$
BEGIN
    IF (SELECT l.editore
        FROM libro as l
        WHERE l.isbn = new.isbn) !=
       (SELECT c.editore
        FROM collana as c
        WHERE c.issn = new.issn)
    THEN RAISE EXCEPTION 'Il libro con ISBN % ha un editore diverso dalla collana con ISSN %', new.isbn, new.issn;
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_editore_libro_collana AFTER INSERT OR UPDATE ON rel_libro_collana
    FOR EACH ROW EXECUTE FUNCTION controllo_editore_libro_collana();


CREATE OR REPLACE FUNCTION controllo_loop_seguito()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF (SELECT l.seguito
        FROM libro as l
        WHERE l.isbn = new.seguito) = new.isbn
    THEN RAISE EXCEPTION 'Un libro non può essere seguito del suo seguito.';
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_loop_seguito AFTER UPDATE OF seguito ON libro
    FOR EACH ROW WHEN ( new.seguito IS NOT NULL )
    EXECUTE FUNCTION controllo_loop_seguito();


CREATE OR REPLACE FUNCTION controllo_data_libro()
RETURNS trigger LANGUAGE plpgsql

AS $$
   DECLARE
       data libro.datauscita%TYPE;
   BEGIN
   SELECT l.datauscita INTO data
   FROM libro as l
   WHERE l.isbn = new.isbn;
   IF data IS NULL OR data > CURRENT_DATE
   THEN RAISE EXCEPTION 'Il libro con ISBN % non è ancora uscito, impossibile aggiungerlo al negozio.', new.isbn;
   END IF;
   RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_data_libro AFTER INSERT OR UPDATE ON rel_libro_negozio
    FOR EACH ROW EXECUTE FUNCTION controllo_data_libro();


CREATE OR REPLACE FUNCTION controlla_temi()
RETURNS trigger LANGUAGE plpgsql
AS $$ BEGIN
    IF (SELECT r.tema
        FROM rivista as r
        WHERE r.issn = new.issn_rivista AND r.numero = new.numero_rivista) != new.tema
    THEN RAISE EXCEPTION 'Il tema dell''articolo (%) è diverso dal tema della rivista a cui appartiene.', new.tema;
        END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_tema_articolo AFTER INSERT OR UPDATE OF issn_rivista, numero_rivista, tema ON articoloscientifico
    FOR EACH ROW WHEN ( new.issn_rivista IS NOT NULL)
    EXECUTE FUNCTION controlla_temi();


CREATE OR REPLACE FUNCTION controllo_serie_libri()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF cerca_idserie_da_isbn(new.isbn) != cerca_idserie_da_isbn(new.seguito)
    THEN RAISE EXCEPTION 'Impossbile aggiungere il libro con ISBN % come seguito del libro con ISBN %: le serie non coincidono.',
        new.seguito, new.isbn;
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_serie_libri AFTER INSERT OR UPDATE OF seguito ON libro
    FOR EACH ROW WHEN ( new.seguito IS NOT NULL )
    EXECUTE FUNCTION controllo_serie_libri();


CREATE OR REPLACE FUNCTION controllo_data_autore_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF (SELECT l.datauscita
        FROM libro as l
        WHERE l.isbn = new.isbn) <= (SELECT a.datanascita
                                     FROM autore as a
                                     WHERE a.idautore = new.idautore)
    THEN RAISE EXCEPTION 'La data di nascita dell''autore viene dopo la data di uscita del libro %.', new.isbn;
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_data_autore_libro AFTER INSERT OR UPDATE ON rel_autore_libro
    FOR EACH ROW EXECUTE FUNCTION controllo_data_autore_libro();


CREATE OR REPLACE FUNCTION controllo_data_autore_articolo()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF (SELECT ar.annopubblicazione
        FROM articoloscientifico as  ar
        WHERE ar.idarticolo = new.idarticolo) <= (SELECT extract(year FROM a.datanascita)
                                     FROM autore as a
                                     WHERE a.idautore = new.idautore)
    THEN RAISE EXCEPTION 'La data di nascita dell''autore viene dopo la data di uscita dell''articolo %.', new.idarticolo;
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_data_autore_articolo AFTER INSERT OR UPDATE ON rel_autore_articolo
    FOR EACH ROW EXECUTE FUNCTION controllo_data_autore_articolo();


CREATE OR REPLACE FUNCTION controllo_data_articolo_rivistaconferenza()
RETURNS trigger LANGUAGE plpgsql
AS $$
   BEGIN
   IF(SELECT r.annopubblicazione
      FROM articoloscientifico as ar JOIN rivista r on r.issn = ar.issn_rivista
      WHERE ar.idarticolo = new.idarticolo AND r.issn = new.issn_rivista AND r.numero = new.numero_rivista) != new.annopubblicazione
   THEN RAISE EXCEPTION 'L''articolo non può essere pubblicato in una rivista pubblicata in un anno diverso';
   ELSIF (SELECT extract(year FROM c.datafine)
       FROM articoloscientifico as ar JOIN conferenza c on c.idconferenza = ar.idconferenza
       WHERE c.idconferenza = new.idconferenza AND ar.idarticolo = new.idarticolo) != new.annopubblicazione
   THEN RAISE EXCEPTION 'L''articolo non può essere pubblicato in una conferenza avvenuta in un anno diverso';
   END IF;
   RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_data_articolo_rivistaconferenza AFTER INSERT OR UPDATE OF idconferenza, issn_rivista, numero_rivista ON articoloscientifico
    FOR EACH ROW EXECUTE FUNCTION controllo_data_articolo_rivistaconferenza();


CREATE OR REPLACE FUNCTION controllo_anno_riviste()
RETURNS trigger LANGUAGE plpgsql
AS $$
   DECLARE
   anno_rivista rivista.annopubblicazione%TYPE;
   riviste_precedenti CURSOR FOR
   SELECT r.annopubblicazione
   FROM rivista as r
   WHERE r.issn = new.issn AND r.numero < new.numero;
   BEGIN
   FOR anno_rivista IN riviste_precedenti LOOP
   IF anno_rivista.annopubblicazione > new.annopubblicazione
   THEN RAISE EXCEPTION 'La rivista inserita % con numero % ha una data precedente a una rivista che la precede.', new.issn,new.numero;
   END IF;
   END LOOP;
   RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_anno_riviste AFTER INSERT OR UPDATE ON rivista
    FOR EACH ROW EXECUTE FUNCTION controllo_anno_riviste();


CREATE OR REPLACE FUNCTION function_librididattici_serie()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF (SELECT l.tipo
        FROM libro as l
        WHERE l.isbn = new.isbn) = 'Didattico'
    THEN RAISE EXCEPTION 'I libri didattici non possono essere aggiunti ad una serie.';
    END IF;
    RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER vincolo_librididattici_serie AFTER INSERT OR UPDATE ON rel_libro_serie
    FOR EACH ROW EXECUTE FUNCTION function_librididattici_serie();
    

CREATE OR REPLACE FUNCTION function_data_librocollana()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
        IF new.data < (SELECT l.datauscita
                       FROM libro as l
                       WHERE l.isbn = new.isbn)
        THEN RAISE EXCEPTION 'La data di aggiunta del libro alla collana non può precedere la data di uscita del libro.';
        END IF;
        RETURN NULL;
    END;$$;

CREATE OR REPLACE TRIGGER vincolo_data_librocollana AFTER INSERT OR UPDATE ON rel_libro_collana
    FOR EACH ROW EXECUTE FUNCTION function_data_librocollana();

    
CREATE OR REPLACE FUNCTION function_collana_dataaggiunta()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    IF new.data < (SELECT c.datapubblicazione
                   FROM collana as c
                   WHERE c.issn = new.issn)
    THEN RAISE EXCEPTION 'Un libro non può essere aggiunto ad una collana in una data precedente alla pubblicazione della collana';
    END IF;
    RETURN NULL;
END;$$;

CREATE OR REPLACE TRIGGER vincolo_collana_dataaggiunta AFTER INSERT OR UPDATE ON rel_libro_collana
    FOR EACH ROW EXECUTE FUNCTION function_collana_dataaggiunta();

CREATE OR REPLACE FUNCTION negozi_serie_completa(in serie serie.idserie%TYPE)
RETURNS table(nome negozio.nome%TYPE) LANGUAGE plpgsql
AS $$
    DECLARE
        n_libri_serie integer;
    BEGIN
        SELECT COUNT (*) INTO n_libri_serie
        FROM rel_libro_serie as rls
        WHERE rls.idserie = serie;
        IF n_libri_serie = 0
        THEN RETURN;
        END IF;
        RETURN QUERY(SELECT n.nome
                     FROM negozio as n
                     WHERE (SELECT COUNT(*)
                            FROM rel_libro_negozio as rln JOIN libro l on l.isbn = rln.isbn JOIN rel_libro_serie rls on l.isbn = rls.isbn
                            WHERE rln.idnegozio = n.idnegozio AND rls.idserie = serie)
                            = (SELECT COUNT (*)
                               FROM rel_libro_serie as rls3
                               WHERE rls3.idserie = serie));
END;$$;