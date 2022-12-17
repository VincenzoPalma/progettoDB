/* TRIGGER FUNCTION PER ELIMINARE LE SERIE VUOTE */

CREATE OR REPLACE FUNCTION function_elimina_serie_vuota()
RETURNS trigger language plpgsql
as $$BEGIN
    /* Conto il numero di libri rimasti nella serie */
    IF (SELECT COUNT(*)
        FROM rel_libro_serie as r
        WHERE r.idserie = old.idserie) = 0
    /* Se il numero è 0 allora elimina la serie */
        THEN DELETE FROM serie WHERE idserie = old.idserie;
        END IF;
    RETURN NULL;
END; $$;



/* TRIGGER FUNCTION PER ELIMINARE LE COLLANE VUOTE */

CREATE OR REPLACE FUNCTION function_elimina_collana_vuota()
RETURNS trigger LANGUAGE plpgsql
as $$BEGIN
    /* Conto il numero di libri rimasti nella collana */
    IF (SELECT COUNT(*)
        FROM rel_libro_collana as r
        WHERE r.issn = old.issn) = 0
    /* Se il numero è 0 allora elimina la collana */
        THEN DELETE FROM collana WHERE issn = old.issn;
        END IF;
    RETURN NULL;
END; $$;



/* TRIGGER FUNCTION PER ELIMINARE LE SALE INUTILIZZATE */

CREATE OR REPLACE FUNCTION function_elimina_sala_inutilizzata()
RETURNS trigger language plpgsql
as $$BEGIN
    /* Conto il numero di libri presentati nella sala */
    IF (SELECT COUNT(*)
        FROM rel_libro_sala as r
        WHERE r.idsala = old.idsala) = 0
    /* Se il numero è 0 allora elimina la sala */
        THEN DELETE FROM sala WHERE idsala = old.idsala;
        END IF;
    RETURN NULL;
END; $$;



/* FUNZIONE CHE CONTROLLA SE UN LIBRO HA UN ISBN */

CREATE OR REPLACE FUNCTION appartenenza_serie(isbn_libro libro.isbn%TYPE)
RETURNS integer language plpgsql
as $$ DECLARE appartenenza integer;
    BEGIN
    /* Controlla il numero di associazioni del libro con serie, sarà un valore tra 0 e 1, ritornerà quello stesso valore */
    appartenenza = (SELECT COUNT(*)
                    FROM rel_libro_serie rls
                    WHERE rls.isbn = isbn_libro);
    RETURN appartenenza;
END;$$;



/* FUNZIONE CHE RESTITUISCE L'IDSERIE DEL LIBRO PRESO COME PARAMETRO */

CREATE OR REPLACE FUNCTION cerca_idserie_da_isbn(isbnlibro libro.isbn%TYPE)
RETURNS integer LANGUAGE plpgsql
as $$
DECLARE serie serie.idserie%TYPE;
BEGIN
    /* Controlla l'appartenenza del libro ad una serie */
    IF appartenenza_serie(isbnlibro) = 0
    THEN RETURN NULL;
    END IF;
    /* Seleziona l'idserie dall'associazione che ha il libro con serie */
    SELECT idserie INTO serie
    FROM rel_libro_serie as rls
    WHERE rls.isbn = isbnlibro;
    RETURN serie;
END;$$;



/* FUNZIONE CHE RESTITUISCE IL NUMERO DI NEGOZI CHE HANNO LA SERIE PRESA COME PARAMETRO, COMPLETA */

CREATE OR REPLACE FUNCTION n_negozi_seriecompleta(serie serie.idserie%TYPE)
RETURNS integer  LANGUAGE plpgsql
as $$
    DECLARE n_negozi integer;
            n_libri_serie integer;
    BEGIN
    /* Controlla che la serie abbia almeno un libro */
    SELECT COUNT (*) INTO n_libri_serie
    FROM rel_libro_serie as rls
    WHERE rls.idserie = serie;
    IF n_libri_serie = 0
    THEN RETURN 0;
    END IF;
    /* Controlla che il numero dei libri nella serie coincida con il numero dei libri di quella serie disponibile in un negozio */
    SELECT COUNT(*) INTO n_negozi
    FROM negozio as n
    WHERE (SELECT COUNT(*)
           FROM rel_libro_negozio as rln JOIN libro l on l.isbn = rln.isbn JOIN rel_libro_serie rls on l.isbn = rls.isbn
           WHERE rln.idnegozio = n.idnegozio AND rls.idserie = serie) = n_libri_serie;
    RETURN n_negozi;
    END;$$;



/* TRIGGER FUNCTION CHE INSERISCE IN NOTIFICA QUANDO E' DISPONIBILE L'INTERA SERIE */

CREATE OR REPLACE FUNCTION crea_notifica()
RETURNS trigger LANGUAGE plpgsql
as $$
    DECLARE serie rel_serie_utente.idserie %TYPE;
            usernametrovato utente.username %TYPE;
		/* Cursore per ottenere gli username degli utenti che hanno la preferenza sulla serie del libro inserito */
            username_preferenze CURSOR FOR
            SELECT rsu.username
            FROM rel_serie_utente as rsu
            WHERE rsu.idserie = serie;
    BEGIN
    /* Ottiene l'idserie del libro, se il libro non ha una serie, la funzione si ferma */
    serie = cerca_idserie_da_isbn(new.isbn);
    IF (serie) IS NULL
    THEN RETURN NULL;
    END IF;
    /* Controlla il numero dei negozi che hanno la serie completa, se è 1 controlla che non esistano già quelle notifiche, e le invia,
	 è inutile tentare di mandare notifiche quando ci sono più di un negozio, perché in quel caso sicuramente le notifiche già esistono */ 
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



/* TRIGGER FUNCTION CHE INVIA NOTIFICHE SULL'INSERIMENTO DI UNA PREFERENZA */

CREATE OR REPLACE FUNCTION crea_notifica_preferenza()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
   	  /* Controlla che il numero dei negozi con la serie completa sia maggiore di 0, in tal caso invia la notifica */
        IF n_negozi_seriecompleta(new.idserie) > 0
        THEN INSERT INTO notifica VALUES (new.username, new.idserie, CURRENT_DATE, CURRENT_TIME);
        END IF;
    RETURN NULL;
    END;
    $$;



/* TRIGGER FUNCTION PER ELIMINARE LE NOTIFICHE DI SERIE NON PIU' COMPLETAMENTE DISPONIBILI */

CREATE OR REPLACE FUNCTION controllo_disponibilita_completa()
RETURNS trigger LANGUAGE plpgsql
as $$
    DECLARE serie integer;
    BEGIN
    /* Ottiene la serie del libro non più disponibile, se non ha serie, la funzione si ferma */
    serie = cerca_idserie_da_isbn(old.isbn);
    IF (serie) IS NULL
    THEN RETURN NULL;
    END IF;
    /* Controlla il numero di negozi rimasti con quella serie completa, se è 0, allora elimina tutte le notifiche per quella serie */
    IF n_negozi_seriecompleta(serie) = 0
        THEN DELETE FROM notifica WHERE idserie = serie;
        END IF;
        RETURN NULL



/* TRIGGER FUNCTION PER ELIMINARE LA NOTIFICA SULLA RIMOZIONE DI UNA PREFERENZA */

CREATE OR REPLACE FUNCTION function_elimina_notifica_preferenza()
RETURNS trigger LANGUAGE plpgsql
as $$
    BEGIN
    /* Elimina la notifica per quell'utente che ha tolto la preferenza, funziona anche se la notifica non esiste */
    DELETE FROM notifica WHERE username = old.username AND idserie = old.idserie;
    RETURN NULL;
    END;$$;



/* TRIGGER FUNCTION PER ACCOMUNARE LE SERIE TRA UN LIBRO E IL SEQUEL */

CREATE OR REPLACE FUNCTION function_accomuna_serie()
RETURNS trigger language plpgsql
as $$BEGIN
    /* Controlla chi tra il libro e il suo sequel appartiene ad una serie, il libro senza serie viene aggiunto alla serie dell'altro */
    IF (appartenenza_serie(new.isbn) = 1 AND appartenenza_serie(new.seguito) = 0)
    THEN INSERT INTO rel_libro_serie VALUES (new.seguito, cerca_idserie_da_isbn(new.isbn));
    ELSEIF (appartenenza_serie(new.isbn) = 0 AND appartenenza_serie(new.seguito) = 1)
    THEN INSERT INTO rel_libro_serie VALUES (new.isbn, cerca_idserie_da_isbn(new.seguito));
    END IF;
    RETURN NULL;
    END;$$;



/* TRIGGER FUNCTION PER ELIMINARE I NEGOZI SENZA SITO E SENZA PUNTI VENDITA */

CREATE OR REPLACE FUNCTION elimina_negozio_senza_canali()
RETURNS trigger LANGUAGE plpgsql
as $$BEGIN
    /* Controlla il numero di punti vendita del negozio, controlla se il sito è nullo, se entrambe le condizioni
	 sono vere, allora elimina il negozio */
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



/* TRIGGER FUNCTION PER ELIMINARE LE RIVISTE E/O CONFERENZE SENZA ARTICOLI */

CREATE OR REPLACE FUNCTION function_cancella_canale_vuoto()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
        /* Controlla il numero di articoli nella rivista, se è 0, elimina la rivista */
        IF (SELECT COUNT(*)
        FROM articoloscientifico as a JOIN rivista r on r.issn = a.issn_rivista and r.numero = a.numero_rivista
        WHERE r.issn = old.issn_rivista AND r.numero = old.numero_rivista) = 0
        THEN DELETE FROM rivista WHERE issn = old.issn_rivista AND numero = old.numero_rivista;
        END IF;
	  /* Controlla il numero di articoli nella conferenza, se è 0, elimina la conferenza */
        IF (SELECT COUNT(*)
        FROM articoloscientifico as a JOIN conferenza c on c.idconferenza = a.idconferenza
        WHERE c.idconferenza = old.idconferenza) = 0
        THEN DELETE FROM conferenza WHERE idconferenza = old.idconferenza;
        END IF;
    RETURN NULL;
    END;$$;



/* TRIGGER FUNCTION PER MANDARE NOTIFICHE DOPO LA RIMOZIONE DI UN LIBRO DA UNA SERIE */

CREATE OR REPLACE FUNCTION function_crea_notifica_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$
    DECLARE usernametrovato utente.username %TYPE;
            /* Cursore per ottenere gli username degli utenti che hanno la preferenza su quella serie */
            username_preferenze CURSOR FOR
            SELECT rsu.username
            FROM rel_serie_utente as rsu
            WHERE rsu.idserie = old.idserie;
    BEGIN
    /* Controlla se esistono negozi, dopo la rimozione del libro, con quella serie completa */
    IF n_negozi_seriecompleta(old.idserie) > 0
        THEN
        FOR usernametrovato IN username_preferenze LOOP
            /* Controlla l'esistenza di notifiche per quella serie, in caso non esistano, le manda */
		IF (EXISTS(SELECT * FROM notifica WHERE idserie = old.idserie AND username = usernametrovato.username)) = FALSE
        	THEN INSERT INTO notifica VALUES (usernametrovato.username, old.idserie, CURRENT_DATE, CURRENT_TIME);
		END IF;
        END LOOP;
    END IF;
    RETURN NULL;
    END;$$;



/* TRIGGER FUNCTION PER ELIMINARE LE NOTIFICHE DOPO L'AGGIUNTA DI UN LIBRO AD UNA SERIE */

CREATE OR REPLACE FUNCTION function_elimina_notifica_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla se il numero di negozi con serie completa, dopo l'aggiunta del libro, sia 0, e in tal caso elimina le notifiche */
    IF n_negozi_seriecompleta(new.idserie) = 0
    THEN DELETE FROM notifica WHERE idserie = new.idserie;
    END IF;
    RETURN NULL;
    END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE UNA COLLANA ABBIA SOLO LIBRI DEL SUO STESSO EDITORE */

CREATE OR REPLACE FUNCTION controllo_editore_libro_collana()
RETURNS trigger LANGUAGE plpgsql
AS $$
BEGIN
    /* Controlla se l'editore del libro aggiunto, sia lo stesso della collana, in caso contrario manda un eccezione */
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



/* TRIGGER FUNCTION PER CONTROLLARE CHE UN LIBRO NON ABBIA UN SEGUITO, IL CUI SEGUITO E' IL LIBRO STESSO */

CREATE OR REPLACE FUNCTION controllo_loop_seguito()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla che l'attributo seguito appartenente al seguito del libro, non sia uguale all'isbn del libro stesso, in tal caso
	 manda un eccezione */
    IF (SELECT l.seguito
        FROM libro as l
        WHERE l.isbn = new.seguito) = new.isbn
    THEN RAISE EXCEPTION 'Un libro non può essere seguito del suo seguito.';
    END IF;
    RETURN NULL;
END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE UN LIBRO NON SIA DISPONIBILE PRIMA DELLA SUA USCITA */

CREATE OR REPLACE FUNCTION controllo_data_libro()
RETURNS trigger LANGUAGE plpgsql

AS $$
   DECLARE
       data libro.datauscita%TYPE;
   BEGIN
   /* Ottiene la data di uscita del libro */
   SELECT l.datauscita INTO data
   FROM libro as l
   WHERE l.isbn = new.isbn;
   /* Controlla che la data di uscita del libro non sia nulla e che sia precedente alla data attuale, altrimenti manda un eccezione */
   IF data IS NULL OR data > CURRENT_DATE
   THEN RAISE EXCEPTION 'Il libro con ISBN % non è ancora uscito, impossibile aggiungerlo al negozio.', new.isbn;
   END IF;
   RETURN NULL;
END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE IL TEMA DI UNA RIVISTA COINCIDA CON IL TEMA DEI SUOI ARTICOLI */

CREATE OR REPLACE FUNCTION controlla_temi()
RETURNS trigger LANGUAGE plpgsql
AS $$ BEGIN
    /* Ottiene il tema della rivista e controlla che sia uguale a quello dell'articolo, in caso contrario manda un eccezione */
    IF (SELECT r.tema
        FROM rivista as r
        WHERE r.issn = new.issn_rivista AND r.numero = new.numero_rivista) != new.tema
    THEN RAISE EXCEPTION 'Il tema dell''articolo (%) è diverso dal tema della rivista a cui appartiene.', new.tema;
        END IF;
    RETURN NULL;
END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE UN LIBRO E IL SUO SEGUITO APPARTENGANO ALLA STESSA SERIE */

CREATE OR REPLACE FUNCTION controllo_serie_libri()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla che entrambi appartengano ad una serie, e controlla che le loro serie coincidano, in caso contrario manda un eccezione */
    IF cerca_idserie_da_isbn(new.isbn) != cerca_idserie_da_isbn(new.seguito)
    THEN RAISE EXCEPTION 'Impossbile aggiungere il libro con ISBN % come seguito del libro con ISBN %: le serie non coincidono.',
        new.seguito, new.isbn;
    END IF;
    RETURN NULL;
END;$$;




/* TRIGGER FUNCTION PER CONTROLLARE CHE L'AUTORE DI UN LIBRO SI NATO PRIMA DELLA PUBBLICAZIONE DEL LIBRO */

CREATE OR REPLACE FUNCTION controllo_data_autore_libro()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla che la data di uscita del libro venga dopo la data di nascita dell'autore, in caso contrario manda un eccezione */
    IF (SELECT l.datauscita
        FROM libro as l
        WHERE l.isbn = new.isbn) <= (SELECT a.datanascita
                                     FROM autore as a
                                     WHERE a.idautore = new.idautore)
    THEN RAISE EXCEPTION 'La data di nascita dell''autore viene dopo la data di uscita del libro %.', new.isbn;
    END IF;
    RETURN NULL;
END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE L'AUTORE DI UN ARTICOLO SI NATO PRIMA DELLA PUBBLICAZIONE DEL ARTICOLO */

CREATE OR REPLACE FUNCTION controllo_data_autore_articolo()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla che l'anno di uscita dell'articolo venga dopo l'anno di nascita dell'autore, in caso contrario manda un eccezione */
    IF (SELECT ar.annopubblicazione
        FROM articoloscientifico as  ar
        WHERE ar.idarticolo = new.idarticolo) <= (SELECT extract(year FROM a.datanascita)
                                     FROM autore as a
                                     WHERE a.idautore = new.idautore)
    THEN RAISE EXCEPTION 'La data di nascita dell''autore viene dopo la data di uscita dell''articolo %.', new.idarticolo;
    END IF;
    RETURN NULL;
END;$$;



/* TRIGGER FUNCTION PER CONTROLLARE CHE UN ARTICOLO NON SI TROVI IN UNA RIVISTA O CONFERENZA IN UN ANNO DIVERSO DALLA LORO PUBBLICAZIONE */

CREATE OR REPLACE FUNCTION controllo_data_articolo_rivistaconferenza()
RETURNS trigger LANGUAGE plpgsql
AS $$
   BEGIN
   /* Controlla che l'anno della rivista coincida con l'anno dell'articolo, se non coincide manda un eccezione */
   IF(SELECT r.annopubblicazione
      FROM articoloscientifico as ar JOIN rivista r on r.issn = ar.issn_rivista
      WHERE ar.idarticolo = new.idarticolo AND r.issn = new.issn_rivista AND r.numero = new.numero_rivista) != new.annopubblicazione
   THEN RAISE EXCEPTION 'L''articolo non può essere pubblicato in una rivista pubblicata in un anno diverso';
   /* Controlla che l'anno della conferenza coincida con l'anno dell'articolo, se non coincide manda un eccezione */
   ELSIF (SELECT extract(year FROM c.datafine)
       FROM articoloscientifico as ar JOIN conferenza c on c.idconferenza = ar.idconferenza
       WHERE c.idconferenza = new.idconferenza AND ar.idarticolo = new.idarticolo) != new.annopubblicazione
   THEN RAISE EXCEPTION 'L''articolo non può essere pubblicato in una conferenza avvenuta in un anno diverso';
   END IF;
   RETURN NULL;
   END;$$;




/* TRIGGER FUNCTION PER CONTROLLARE L'ORDINE CRONOLOGICO TRA I NUMERI DI UNA RIVISTA */

CREATE OR REPLACE FUNCTION controllo_anno_riviste()
RETURNS trigger LANGUAGE plpgsql
AS $$
   DECLARE
   anno_rivista rivista.annopubblicazione%TYPE;
   /* Cursore per ottenere i numeri della rivista precedenti a quello aggiunto */
   riviste_precedenti CURSOR FOR
   SELECT r.annopubblicazione
   FROM rivista as r
   WHERE r.issn = new.issn AND r.numero < new.numero;
   BEGIN
   /* Per ogni numero della rivista, controlla che il suo anno sia minore o uguale di quello del numero inserito, altrimenti manda un eccezione */
   FOR anno_rivista IN riviste_precedenti LOOP
   IF anno_rivista.annopubblicazione > new.annopubblicazione
   THEN RAISE EXCEPTION 'La rivista inserita % con numero % ha una data precedente a una rivista che la precede.', new.issn,new.numero;
   END IF;
   END LOOP;




/* TRIGGER FUNCTION PER CONTROLLARE CHE I LIBRI DIDATTICI NON APPARTENGANO A SERIE */

CREATE OR REPLACE FUNCTION function_librididattici_serie()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Seleziona il tipo del libro inserito nella serie, se è didattico allora manda un eccezione */
    IF (SELECT l.tipo
        FROM libro as l
        WHERE l.isbn = new.isbn) = 'Didattico'
    THEN RAISE EXCEPTION 'I libri didattici non possono essere aggiunti ad una serie.';
    END IF;
    RETURN NULL;
    END;$$;
   RETURN NULL;
END;$$;




/* FUNCTION TRIGGER PER CONTROLLARE CHE LA DATA DI USCITA DI UN LIBRO NON VENGA DOPO LA DATA DI AGGIUNTA DI QUEL LIBRO AD UNA COLLANA */

CREATE OR REPLACE FUNCTION function_data_librocollana()
RETURNS trigger LANGUAGE plpgsql
AS $$
    BEGIN
        /* Controlla che la data di uscita del libro, sia minore di quella della sua aggiunta alla collana, in caso contrario manda un eccezione */
        IF new.data < (SELECT l.datauscita
                       FROM libro as l
                       WHERE l.isbn = new.isbn)
        THEN RAISE EXCEPTION 'La data di aggiunta del libro alla collana non può precedere la data di uscita del libro.';
        END IF;
        RETURN NULL;
    END;$$;


/* TRIGGER FUNCTION PER CONTROLLARE CHE LA DATA DI PUBBLICAZIONE DELLA COLLANA NON VENGA DOPO LA DATA DI AGGIUNTA DI UN LIBRO A QUELLA COLLANA */

CREATE OR REPLACE FUNCTION function_collana_dataaggiunta()
RETURNS trigger LANGUAGE plpgsql
AS $$BEGIN
    /* Controlla che la data di pubblicazione della collana sia minore della data di aggiunta del libro, in caso contrario manda un eccezione */
    IF new.data < (SELECT c.datapubblicazione
                   FROM collana as c
                   WHERE c.issn = new.issn)
    THEN RAISE EXCEPTION 'Un libro non può essere aggiunto ad una collana in una data precedente alla pubblicazione della collana';
    END IF;
    RETURN NULL;
END;$$;




/* FUNZIONE PER SELEZIONARE IL NOME DEI NEGOZI CHE HANNO DISPONIBILE LA SERIE PRESA COME PARAMETRO */

CREATE OR REPLACE FUNCTION negozi_serie_completa(in serie serie.idserie%TYPE)
RETURNS table(nome negozio.nome%TYPE) LANGUAGE plpgsql
AS $$
    DECLARE
        n_libri_serie integer;
    BEGIN
        /* Ottiene il numero dei libri nella serie */
        SELECT COUNT (*) INTO n_libri_serie
        FROM rel_libro_serie as rls
        WHERE rls.idserie = serie;
        IF n_libri_serie = 0
        THEN RETURN;
        END IF;
        /* Ritorna il risultato della query, ovvero il nome dei negozi con la serie completa, controllando che il numero dei libri
	     del negozio di quella serie, sia uguale al numero di libri nella serie */
        RETURN QUERY(SELECT n.nome
                     FROM negozio as n
                     WHERE (SELECT COUNT(*)
                            FROM rel_libro_negozio as rln JOIN libro l on l.isbn = rln.isbn JOIN rel_libro_serie rls on l.isbn = rls.isbn
                            WHERE rln.idnegozio = n.idnegozio AND rls.idserie = serie)
                            = (SELECT COUNT (*)
                               FROM rel_libro_serie as rls3
                               WHERE rls3.idserie = serie));
END;$$;