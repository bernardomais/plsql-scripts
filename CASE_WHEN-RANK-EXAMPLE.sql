SELECT

CODVEND,
APELIDO,
NVL(FATUR, 0) AS FATUR,

/* PREMIA OS 18 PRIMEIROS */
(CASE WHEN STATUS = 'OK' AND RANK < 19 THEN 'PREMIO' END) AS PREMIACAO,

/* DISTRIBUICAO DE PREMIOS */
(CASE WHEN RANK = 1 THEN 'R$ 900.00' ELSE 
    (CASE WHEN RANK = 2 THEN 'R$ 800,00' ELSE
        (CASE WHEN RANK = 3 THEN 'R$ 700,00' ELSE
            (CASE WHEN RANK = 4 THEN 'R$ 500,00' ELSE 
                (CASE WHEN RANK = 5 THEN 'R$ 400,00' ELSE
                    (CASE WHEN RANK = 6 THEN 'R$ 300,00' ELSE 
                        (CASE WHEN RANK BETWEEN 7 AND 18 THEN 'R$ 200,00' END)
                    END)
                END)
            END)
        END)
    END)
END) AS VLR_PREMIO,

FAT_GLOBAL,
OBJETIV,

DT_INICIO,
DT_FINAL,

/* ESSAS FUNCTIONS NAO SAO ENCONTRADAS EM PRODUCAO, MAS, NA BASE DE HOMOLOGACAO FUNCIONAM */
-- RMD_DIAS_UTEIS_DECORRIDOS(DT_INICIO, DT_FINAL) AS DIAS_DECORRIDOS,
-- RMD_DIAS_UTEIS_DURACAO(DT_INICIO, DT_FINAL) AS DIAS_DURACAO,
-- ROUND ((FAT_GLOBAL / RMD_DIAS_UTEIS_DECORRIDOS(DT_INICIO, DT_FINAL) * RMD_DIAS_UTEIS_DURACAO(DT_INICIO, DT_FINAL)), 2) AS FAT_PROJECAO,
-- ROUND ((FAT_GLOBAL / RMD_DIAS_UTEIS_DECORRIDOS(DT_INICIO, DT_FINAL) * RMD_DIAS_UTEIS_DURACAO(DT_INICIO, DT_FINAL)) / OBJETIV * 100, 2) AS PERC_PROJ_OBJ1

RANK


FROM 
(
SELECT

VEN.CODVEND,
VEN.APELIDO,
NVL(FATUR, 0) AS FATUR,
STATUS,

FAT_GLOBAL,
OBJETIV,

DT_INICIO,
DT_FINAL,

(CASE WHEN FATUR IS NOT NULL THEN ROWNUM END) AS RANK

FROM TGFVEN VEN
LEFT JOIN
(
/* ********************  inicio apuracao faturamento */
SELECT

V.APELIDO AS VEND_FAT,
SUM((I.VLRTOT-I.VLRDESC)*T.GOLDEV) AS FATUR,
(CASE WHEN SUM((I.VLRTOT-I.VLRDESC)*T.GOLDEV)  >= 12000 THEN 'OK' END) AS STATUS

FROM TGFCAB C, TGFITE I, TGFTOP T, TGFPRO P, TGFVEN V

WHERE
TRUNC(C.DTFATUR) BETWEEN '01/06/2018' AND '31/08/2019' -- ALTERAR ESSAS DATAS PARA AS DATAS REAIS DA CAMPANHA (DATAS DE TESTE)
AND P.CODPARCFORN=102130
AND T.GOLSINAL=-1
AND C.STATUSNOTA='L'

AND I.NUNOTA=C.NUNOTA
AND P.CODPROD=I.CODPROD
AND V.CODVEND=C.CODVEND
AND T.CODTIPOPER=C.CODTIPOPER
AND T.DHALTER=C.DHTIPOPER

GROUP BY V.APELIDO

ORDER BY FATUR DESC
/* ********************  fim apuracao faturamento */

) ON VEND_FAT=VEN.APELIDO

,

(
/* ************************ inicio outras definições */
SELECT

FAT_VEND AS FAT_GLOBAL,
'R$ 600.000,00' AS OBJETIV,
TO_DATE ('01/06/2018', 'DD/MM/YYYY') AS DT_INICIO, -- ALTERAR ESSAS DATAS PARA AS DATAS REAIS DA CAMPANHA (DATAS DE TESTE)
TO_DATE ('31/08/2019', 'DD/MM/YYYY') AS DT_FINAL   -- ALTERAR ESSAS DATAS PARA AS DATAS REAIS DA CAMPANHA (DATAS DE TESTE)

FROM
(
/* ************************ inicio apuração fatumento global */
SELECT

SUM ((I.VLRTOT-I.VLRDESC)*T.GOLDEV) AS FAT_VEND

FROM TGFCAB C, TGFITE I, TGFTOP T, TGFPRO P, TGFVEN V, AD_OBJETIVOSRMD O

WHERE
P.CODPARCFORN = 102130
AND TRUNC(C.DTFATUR) BETWEEN '01/06/2018' AND '31/08/2019' -- ALTERAR ESSAS DATAS PARA AS DATAS REAIS DA CAMPANHA (DATAS DE TESTE)
AND T.GOLSINAL=-1
AND C.STATUSNOTA='L'
AND O.CODCAMP=18

AND I.NUNOTA=C.NUNOTA
AND P.CODPROD=I.CODPROD
AND V.CODVEND=C.CODVEND
AND O.CODPARTIC=C.CODVEND
AND T.CODTIPOPER=C.CODTIPOPER
AND T.DHALTER=C.DHTIPOPER
/* ************************ fim apuração fatumento global */
)
/* ************************ fim outras definições */
)

, AD_OBJETIVOSRMD OBJ


WHERE
OBJ.CODCAMP=18
AND VEN.CODVEND NOT IN (SELECT AD_APONTA_VENDPF FROM TGFVEN WHERE AD_APONTA_VENDPF IS NOT NULL)

AND OBJ.CODPARTIC=VEN.CODVEND
);