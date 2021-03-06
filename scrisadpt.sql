USE [Woodsland-HUNG]
GO
/****** Object:  Schema [app]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [app]
GO
/****** Object:  Schema [base]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [base]
GO
/****** Object:  Schema [eof]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [eof]
GO
/****** Object:  Schema [fpm]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [fpm]
GO
/****** Object:  Schema [hr]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [hr]
GO
/****** Object:  Schema [lgt]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [lgt]
GO
/****** Object:  Schema [nlg]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [nlg]
GO
/****** Object:  Schema [prod]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [prod]
GO
/****** Object:  Schema [wood]    Script Date: 5/19/2021 1:34:36 PM ******/
CREATE SCHEMA [wood]
GO
/****** Object:  View [nlg].[View_BOM]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [nlg].[View_BOM]
AS
  with  temp(MATERIALS_ID,ITEM_ID)
  as

  (SELECT        MATERIALS_ID, ITEM_ID
FROM            prod.BOM
WHERE        (factoryId = 100000)
UNION ALL
SELECT        b.MATERIALS_ID, a.ITEM_ID
FROM            temp AS a INNER JOIN
                         prod.BOM AS b ON a.MATERIALS_ID = b.ITEM_ID
WHERE        (b.factoryId = 100000))
    SELECT        I.NAME, I.ID AS ITEM_ID, I1.NAME AS paren, I1.ID AS paren_id, D .NAME AS congdoan, R1.STEP_ID, R1.factoryId
     FROM            prod.ROUTING AS R LEFT OUTER JOIN
                              base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                              temp AS te ON te.ITEM_ID = I1.ID LEFT OUTER JOIN
                              base.ITEM AS I ON I.ID = te.MATERIALS_ID LEFT OUTER JOIN
                              prod.ROUTING AS R1 ON I.ID = R1.ITEM_ID AND R1.factoryId = 100000 LEFT OUTER JOIN
                              base.DEPARTMENT AS D ON D .ID = R1.STEP_ID
     WHERE        (R.STEP_ID IN (100282, 100270, 100273)) AND (I.NAME IS NOT NULL) AND (R.[ORDER] = 1) AND (R.factoryId = 100000)
UNION ALL
SELECT DISTINCT I1.NAME NAME, R.ITEM_ID, I1.NAME paren, R.ITEM_ID paren_id, D .NAME congdoan, R.STEP_ID, R.factoryId
FROM            prod.ROUTING AS R LEFT OUTER JOIN
                         base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D .ID = R.STEP_ID
WHERE        (R.STEP_ID IN (100282, 100270, 100273)) AND (R.[ORDER] = 1) AND (R.factoryId = 100000)
GO
/****** Object:  View [dbo].[View_TonDauKy]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_TonDauKy]
AS
SELECT DISTINCT OS.itemId, OS.stepId, OS.quantity, OS.createdAt, B.paren_id AS market
FROM            base.ITEM AS i LEFT OUTER JOIN
                             (SELECT        ITEM_ID AS itemId, DEPARTMENT_ID AS stepId, QUANTITY AS quantity, createdAt, nguonPhoi
                               FROM            prod.OPENING_STOCK) AS OS ON OS.itemId = i.ID LEFT OUTER JOIN
                         nlg.View_BOM AS B ON B.ITEM_ID = OS.itemId
WHERE        (OS.nguonPhoi = N'Tại tổ') AND (OS.createdAt >= '20210505') AND (B.paren_id IS NOT NULL)
GO
/****** Object:  View [dbo].[View_DatKeHoach]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_DatKeHoach]
AS
SELECT        p.PO AS poCode, SUM(iip.QUANTITY) AS soLuongDat
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS p ON iip.PACKAGE_ID = p.ID
WHERE        (p.TYPE_ID = 100026) AND (p.PO IS NOT NULL)
GROUP BY p.PO
GO
/****** Object:  View [dbo].[View_ThucHienKeHoach]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ThucHienKeHoach]
AS
SELECT        p.id, p.guid, p.code, p.parent, p.stepId, p.itemId, CASE WHEN (p.keHoach - p.ton) > 0 THEN p.keHoach - p.ton ELSE 0 END AS quantity, p.counts, p.[order], p.time, p.shift, p.week, p.year, p.market, p.ton, p.soLuongUuTien, 
                         p.hanMucTon, p.soLuongCanSanXuat, p.status, p.type, p.root, p.number, p.factor, p.keHoach + p.hanMucTon AS keHoach, p.capPhoi, p.taoPhoi, p.ngayDongGoi, p.thoiGianCho, p.thoiGianBatDau, p.ngayLamViec, 
                         p.thoiGianCanSanXuat, p.thoiGianThucHien, p.caLamViec, p.deletedAt, d.soLuongDat, p.factoryId, p.loiCongDon, M.NAME AS sanpham
FROM            prod.PO AS p LEFT OUTER JOIN
                         dbo.View_DatKeHoach AS d ON p.code = d.poCode LEFT OUTER JOIN
                         base.MARKET AS M ON M.CODE = p.root
WHERE        (p.endPO = 0) AND (p.deletedAt IS NULL) AND (p.approvedAt IS NOT NULL)
GO
/****** Object:  View [dbo].[View_XUAT_QC]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_XUAT_QC]
AS
SELECT        D.ID, D.NAME, GD.CODE, P.DESTINATION_ID AS [TO], P.ITEM_FROM_ID, IIP.ITEM_ID, IIP.QUANTITY AS EXPORT, P.CREATE_DATE
FROM            prod.PACKAGE AS P LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS IIP ON IIP.PACKAGE_ID = P.ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D.ID = P.SOURCE_ID LEFT OUTER JOIN
                         base.GLOBAL_DATE AS GD ON GD.YEAR = YEAR(P.CREATE_DATE) AND GD.MONTH = MONTH(P.CREATE_DATE) AND GD.DAY = DAY(P.CREATE_DATE)
WHERE        (P.CREATE_DATE >= '20210422') AND (P.SOURCE_ID = 100081)
GO
/****** Object:  View [dbo].[View_NHAP_QC]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_NHAP_QC]
AS
SELECT        D.ID, D.NAME, GD.CODE, P.SOURCE_ID AS [FROM], IIP.ITEM_ID, IIP.QUANTITY AS IMPORT, P.CREATE_DATE, P.factoryId
FROM            prod.PACKAGE AS P LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS IIP ON IIP.PACKAGE_ID = P.ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D.ID = P.DESTINATION_ID LEFT OUTER JOIN
                         base.GLOBAL_DATE AS GD ON GD.YEAR = YEAR(P.CREATE_DATE) AND GD.MONTH = MONTH(P.CREATE_DATE) AND GD.DAY = DAY(P.CREATE_DATE)
WHERE        (P.CREATE_DATE > '20210422') AND (P.DESTINATION_ID = 100081)
GO
/****** Object:  View [dbo].[View_TON_QC]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_TON_QC]
AS
SELECT        ID, [FROM], ITEM_ID, REMAIN, factoryId
FROM            (SELECT        N.ID, N.factoryId, N.[FROM], N.ITEM_ID, CASE WHEN N .IMPORT IS NULL AND X.EXPORT IS NULL THEN 0 WHEN N .IMPORT IS NULL AND X.EXPORT IS NOT NULL THEN X.EXPORT * (- 1) 
                                                    WHEN N .IMPORT IS NOT NULL AND X.EXPORT IS NULL THEN N .IMPORT WHEN N .IMPORT IS NOT NULL AND X.EXPORT IS NOT NULL 
                                                    THEN N .IMPORT - X.EXPORT ELSE N .IMPORT - X.EXPORT END AS REMAIN
                          FROM            (SELECT        ID, [FROM], ITEM_ID, SUM(IMPORT) AS IMPORT, factoryId
                                                    FROM            dbo.View_NHAP_QC
                                                    GROUP BY ID, [FROM], ITEM_ID, factoryId) AS N LEFT OUTER JOIN
                                                        (SELECT        ID, ITEM_FROM_ID, ITEM_ID, SUM(EXPORT) AS EXPORT
                                                          FROM            dbo.View_XUAT_QC
                                                          GROUP BY ID, ITEM_FROM_ID, ITEM_ID) AS X ON N.ID = X.ID AND N.[FROM] = X.ITEM_FROM_ID AND N.ITEM_ID = X.ITEM_ID) AS TON
WHERE        (REMAIN > 0)
GO
/****** Object:  View [dbo].[View_XUAT_TRU_TON]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[View_XUAT_TRU_TON]
AS
SELECT S.ID,
S.[NAME],
GD.CODE,
P.DESTINATION_ID AS [TO],
MIP.ITEM_ID,
SUM(MIP.QUANTITY) AS EXPORT
FROM dbo.[PACKAGE] P -- xuất hàng để trừ tồn kho 
LEFT JOIN dbo.[ITEM_IN_PACKAGE] IIP ON IIP.PACKAGE_ID = P.ID
LEFT JOIN dbo.[MATERIALS_IN_PACKAGE] MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
LEFT JOIN base.[STEP] S ON S.ID = P.SOURCE_ID
LEFT JOIN base.[GLOBAL_DATE] GD ON GD.YEAR = YEAR(P.CREATE_DATE) AND GD.MONTH = MONTH(P.CREATE_DATE) AND GD.DAY = DAY(P.CREATE_DATE)
WHERE P.VERIFY_BY IS NOT NULL
GROUP BY S.ID,
S.[NAME],
GD.CODE,
P.DESTINATION_ID,
MIP.ITEM_ID
GO
/****** Object:  View [dbo].[View_NHAP]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[View_NHAP]
AS
SELECT 
S.ID,
S.[NAME],
GD.CODE,
P.SOURCE_ID AS [FROM],
IIP.ITEM_ID,
SUM(IIP.QUANTITY) IMPORT
FROM dbo.PACKAGE P -- nhâp kho
LEFT JOIN dbo.[ITEM_IN_PACKAGE] IIP ON IIP.PACKAGE_ID = P.ID
LEFT JOIN base.[STEP] S ON S.ID = P.DESTINATION_ID
LEFT JOIN base.[GLOBAL_DATE] GD ON GD.YEAR = YEAR(P.CREATE_DATE) AND GD.MONTH = MONTH(P.CREATE_DATE) AND GD.DAY = DAY(P.CREATE_DATE)
WHERE P.VERIFY_BY IS NOT NULL
GROUP BY S.ID,
S.[NAME],
GD.CODE,
P.SOURCE_ID,
IIP.ITEM_ID
GO
/****** Object:  View [dbo].[View_XUAT]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[View_XUAT]
AS
SELECT S.ID,
S.[NAME],
GD.CODE,
P.DESTINATION_ID AS [TO],
IIP.ITEM_ID,
SUM(IIP.QUANTITY) EXPORT
FROM dbo.[PACKAGE] P -- xuất hàng thành phẩm kho 
LEFT JOIN dbo.[ITEM_IN_PACKAGE] IIP ON IIP.PACKAGE_ID = P.ID
LEFT JOIN base.[STEP] S ON S.ID = P.SOURCE_ID
LEFT JOIN base.[GLOBAL_DATE] GD ON GD.YEAR = YEAR(P.CREATE_DATE) AND GD.MONTH = MONTH(P.CREATE_DATE) AND GD.DAY = DAY(P.CREATE_DATE)
WHERE P.VERIFY_BY IS NOT NULL
GROUP BY S.ID,
S.[NAME],
GD.CODE,
P.DESTINATION_ID,
IIP.ITEM_ID

GO
/****** Object:  View [dbo].[View_TON]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[View_TON]
AS
SELECT CASE
	WHEN N.ID IS NOT NULL THEN N.ID
	WHEN XTT.ID IS NOT NULL THEN XTT.ID
	ELSE X.ID
END STEP_ID,
CASE
	WHEN N.CODE IS NOT NULL THEN N.CODE
	WHEN XTT.CODE IS NOT NULL THEN XTT.CODE
	ELSE X.CODE
END CODE,
CASE
	WHEN N.ITEM_ID IS NOT NULL THEN N.ITEM_ID
	WHEN XTT.ITEM_ID IS NOT NULL THEN XTT.ITEM_ID
	ELSE X.ITEM_ID
END ITEM_ID,
N.IMPORT,
XTT.EXPORT EXPORT_NVL,
X.EXPORT,
CASE 
	WHEN N.IMPORT IS NULL THEN XTT.EXPORT * (-1)
	WHEN XTT.EXPORT IS NULL THEN N.IMPORT
	ELSE N.IMPORT - XTT.EXPORT
END REMAIN
FROM View_NHAP N
FULL JOIN View_XUAT_TRU_TON XTT ON XTT.ID = N.ID AND XTT.CODE = N.CODE AND XTT.ITEM_ID = N.ITEM_ID
FULL JOIN View_XUAT X ON X.ID = N.ID AND X.CODE = N.CODE AND X.ITEM_ID = N.ITEM_ID
WHERE N.ID IS NOT NULL 
OR XTT.ID IS NOT NULL

GO
/****** Object:  View [dbo].[View_Package_100026]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Package_100026]
AS
SELECT       pa.DESTINATION_ID AS stepId, iip.ITEM_ID AS itemId, SUM(iip.QUANTITY) AS nhap
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON iip.PACKAGE_ID = pa.ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code
WHERE        (pa.TYPE_ID = 100026) AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL) AND (po.endPO = 0)
GROUP BY pa.DESTINATION_ID, iip.ITEM_ID
GO
/****** Object:  View [dbo].[View_Materials_Package_100026_100004]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Materials_Package_100026_100004]
AS
SELECT       pa.SOURCE_ID AS stepId, mip.ITEM_ID AS itemId, SUM(mip.QUANTITY) AS xuat
FROM            prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON pa.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code
WHERE        (pa.TYPE_ID IN (100026, 100004)) AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL) AND (po.endPO = 0)
GROUP BY pa.SOURCE_ID, mip.ITEM_ID
GO
/****** Object:  View [dbo].[View_ThieuPhoi]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ThieuPhoi]
AS
SELECT       TOP (100) PERCENT d.NAME AS stepName, i.NAME AS itemName, t.nhap, t.xuat, t.ton
FROM            (SELECT       n.stepId, n.itemId, n.nhap, x.xuat, n.nhap - CASE WHEN x.xuat IS NULL THEN 0 ELSE x.xuat END AS ton
                          FROM            dbo.View_Package_100026 AS n LEFT OUTER JOIN
                                                   dbo.View_Materials_Package_100026_100004 AS x ON n.itemId = x.itemId AND n.stepId = x.stepId) AS t LEFT OUTER JOIN
                         base.DEPARTMENT AS d ON t.stepId = d.ID LEFT OUTER JOIN
                         base.ITEM AS i ON t.itemId = i.ID
ORDER BY stepName
GO
/****** Object:  View [dbo].[Report_exportGoods]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[Report_exportGoods]
AS
SELECT L2.[DATE],FS.NAME N'Nhà máy', XS.NAME N'Xưởng', DS.NAME N'Bộ phận',FD.NAME FACTORY_DETINATION, XD.NAME XUONG_DETINATION, DD.NAME N'Nơi xuất',L2.ITEM_ID, 
'['+ CAST( CAST(I.LENGTH AS INT) AS NVARCHAR(50)) + ' ' + CAST( CAST(I.WIDTH AS INT) AS NVARCHAR(50)) + ' ' + CAST( CAST(I.HEIGHT AS INT) AS NVARCHAR(50)) + '] ' + I.NAME N'Chi tiết/cụm',
L2.QUANTITY N'Thanh',
((I.LENGTH * I.WIDTH * I.HEIGHT) * L2.QUANTITY) / 1000000000 'M3'
FROM (
    SELECT L1.[DATE],SS.DEPARTMENT_ID SOURCE_ID,DOD.DEPARTMENT_ID DESTINATION_ID,L1.ITEM_ID,L1.QUANTITY
    FROM (
        SELECT [DATE],SOURCE_ID,DESTINATION_ID,ITEM_ID,SUM(QUANTITY) QUANTITY
        FROM (
            SELECT CONVERT(DATE,P.CREATE_DATE) DATE, P.SOURCE_ID,P.DESTINATION_ID, IIP.ITEM_ID,IIP.QUANTITY
            FROM dbo.PACKAGE P
            LEFT JOIN dbo.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
            WHERE P.SOURCE_ID <> 100001 
            AND P.SOURCE_ID <> 100098              --100001 100098  Xe nâng không cần thống kê
        ) L0 -- Lấy ra số lượng item chuyển đi sang công đoạn khác, loại bỏ những công đoạn không cần thiết ( xe nâng dữ liệu null )
        GROUP BY L0.[DATE], L0.SOURCE_ID,L0.DESTINATION_ID, L0.ITEM_ID
    ) L1 -- Tổng hợp số lượng sản phẩm chuyển sang công đoạn khác theo ngày, công đoạn, sản phẩm.
    LEFT JOIN base.STEP SS ON SS.ID = L1.SOURCE_ID -- Lấy ra bộ phận của công đoạn
    LEFT JOIN base.STEP SOD ON SOD.DEPARTMENT_ID = SS.DEPARTMENT_ID AND SOD.ID = L1.DESTINATION_ID -- join với công đoạn mà phải chung công đoạn và đích giống với công đoạn đó, để loại đi
    LEFT JOIN base.STEP DOD ON DOD.ID = L1.DESTINATION_ID
    WHERE SOD.ID IS NULL
) L2 -- upto lên cấp bộ phận
LEFT JOIN base.DEPARTMENT DS ON DS.ID = L2.SOURCE_ID
LEFT JOIN base.XUONG XS ON XS.ID = DS.XUONG_ID
LEFT JOIn base.FACTORY FS ON FS.ID = XS.FACTORY_ID
LEFT JOIN base.DEPARTMENT DD ON DD.ID = L2.DESTINATION_ID
LEFT JOIN base.XUONG XD ON XD.ID = DD.XUONG_ID
LEFT JOIN base.FACTORY FD ON FD.ID = XD.FACTORY_ID
LEFT JOIN base.ITEM I ON I.ID = L2.ITEM_ID
WHERE DS.ID <> 100006 AND DS.ID <> 100015 -- bỏ thống kê của QC













GO
/****** Object:  View [dbo].[V_GhiDat100026s]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GhiDat100026s]
AS
SELECT        pa.SOURCE_ID AS stepId, mip.ITEM_ID AS itemId, mip.QUANTITY AS xuat, pa.CREATE_DATE AS createdAt, pa.VERIFY_DATE AS updatedAt, iip.ID, m.PRODUCT_ID AS market
FROM            prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON pa.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code LEFT OUTER JOIN
                         base.MARKET AS m ON m.CODE = po.root
WHERE        (pa.TYPE_ID = 100026) AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL) AND (po.endPO = 0) AND (pa.CREATE_DATE >= '2021-05-06 18:00:45.1033333 +00:00') AND (pa.REMEDIES_ID IS NULL)
GO
/****** Object:  View [dbo].[V_GhiLoi100004s]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GhiLoi100004s]
AS
SELECT        pa.SOURCE_ID AS stepId, mip.ITEM_ID AS itemId, mip.QUANTITY AS loi, pa.CREATE_DATE AS createdAt, pa.VERIFY_DATE AS updatedAt, iip.ID, m.PRODUCT_ID AS market
FROM            prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON pa.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code LEFT OUTER JOIN
                         base.MARKET AS m ON m.CODE = po.root
WHERE        (pa.TYPE_ID = 100004) AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL) AND (po.endPO = 0) AND (pa.CREATE_DATE >= '2021-05-06 18:00:45.1033333 +00:00') AND (pa.REMEDIES_ID IS NULL)
GO
/****** Object:  View [dbo].[V_NhapVe100026s]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_NhapVe100026s]
AS
SELECT        pa.DESTINATION_ID AS stepId, iip.ITEM_ID AS itemId, iip.QUANTITY AS nhap, pa.CREATE_DATE AS createdAt, pa.VERIFY_DATE AS updatedAt, iip.ID, m.PRODUCT_ID AS market
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON iip.PACKAGE_ID = pa.ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code LEFT OUTER JOIN
                         base.MARKET AS m ON m.CODE = po.root
WHERE        (pa.TYPE_ID = 100026) AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL) AND (po.endPO = 0) AND (pa.VERIFY_DATE IS NOT NULL) AND (pa.CREATE_DATE >= '2021-05-06 18:00:45.1033333 +00:00') AND 
                         (pa.KH_VERIFY_BY IS NULL)
GO
/****** Object:  View [dbo].[View_baoCaoTinhHinhTHucHien]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[View_baoCaoTinhHinhTHucHien]
AS
    SELECT 
	P.SOURCE_ID departmentId,
	D.[CODE] departmentCode,
    D.[NAME] departmentName,
    GD.[YEAR] [year],
    GD.WEEK week,
    GD.WEEK_DAY dayOfWeek,
    GD.DATE date,
    IP.ID parentId,
    IP.NAME parentName,
    B.RATE rate,
    IIP.ITEM_ID itemId,   
    I.NAME itemName,
	U.NAME unit,
    I.LENGTH length,
    I.WIDTH width,
    I.HEIGHT height,
    I.VOLUMN * SUM(IIP.QUANTITY) volumn,
    SUM(IIP.QUANTITY) quantity
    FROM prod.PACKAGE P
    LEFT JOIN base.GLOBAL_DATE GD ON GD.CODE = CAST(P.CREATE_DATE AS DATE)
    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
    LEFT JOIN base.ITEM I ON I.ID  = IIP.ITEM_ID
	LEFT JOIN base.UNIT U ON U.ID = I.UNIT_ID
    LEFT JOIN base.DEPARTMENT D ON D.ID = P.SOURCE_ID
    LEFT JOIN prod.BOM B ON B.MATERIALS_ID = I.ID
    LEFT JOIN base.ITEM IP ON IP.ID = B.ITEM_ID
    WHERE P.DESTINATION_ID <> 100078
    AND  P.DESTINATION_ID <> 100079
    AND  P.DESTINATION_ID <> 100080
    AND  P.DESTINATION_ID <> 100081
    GROUP BY P.SOURCE_ID ,
    D.CODE,
	D.NAME ,
    GD.[YEAR] ,
    GD.WEEK ,
    GD.WEEK_DAY,
    GD.DATE ,
    IP.ID ,
    IP.NAME ,
    B.RATE ,
    IIP.ITEM_ID ,   
    I.NAME ,
	U.NAME,
    I.LENGTH ,
    I.WIDTH ,
    I.HEIGHT ,
    I.VOLUMN

GO
/****** Object:  View [dbo].[View_Bom]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Bom]
AS
SELECT        ID AS id, ITEM_ID AS itemId, MATERIALS_ID AS materialsId, RATE AS rate, factoryId
FROM            prod.BOM
GO
/****** Object:  View [dbo].[View_conthuchien]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_conthuchien]
AS
SELECT        TOP (100) PERCENT code, ton, approvedAt, market, loiCongDon, keHoach, stepId, stepName, root, productName, itemId, itemCode, itemName, itemLength, itemWidth, itemHeight, target, 'totalQuantity' AS Expr1, 
                         conThucHien
FROM            (SELECT        PO.code, PO.ton, PO.approvedAt, PO.market, PO.loiCongDon, ROUND(PO.keHoach, 6) AS keHoach, D.ID AS stepId, D.NAME AS stepName, M.NAME AS root, P.NAME AS productName, I.ID AS itemId, 
                                                    I.CODE AS itemCode, I.NAME AS itemName, I.LENGTH AS itemLength, I.WIDTH AS itemWidth, I.HEIGHT AS itemHeight, ROUND(PO.quantity, 6) AS target, CASE WHEN SL.quantity IS NULL 
                                                    THEN 0 ELSE ROUND(SL.quantity, 6) END AS 'totalQuantity', ROUND(PO.keHoach - PO.soLuongUuTien + PO.hanMucTon + PO.loiCongDon - (CASE WHEN SL.quantity IS NULL THEN 0 ELSE ROUND(SL.quantity, 6) 
                                                    END), 6) AS conThucHien
                          FROM            prod.PO AS PO LEFT OUTER JOIN
                                                    base.ITEM AS I ON I.ID = PO.itemId LEFT OUTER JOIN
                                                    base.DEPARTMENT AS D ON D.ID = PO.stepId LEFT OUTER JOIN
                                                    base.MARKET AS M ON M.CODE = PO.root LEFT OUTER JOIN
                                                    base.ITEM AS P ON P.ID = M.PRODUCT_ID LEFT OUTER JOIN
                                                        (SELECT        P.PO, SUM(IIP.QUANTITY) AS quantity
                                                          FROM            prod.PACKAGE AS P LEFT OUTER JOIN
                                                                                    prod.PACKAGE_TYPE AS PT ON PT.ID = P.TYPE_ID LEFT OUTER JOIN
                                                                                    prod.ITEM_IN_PACKAGE AS IIP ON IIP.PACKAGE_ID = P.ID
                                                          WHERE        (PT.TYPE_ID <> 100000 OR
                                                                                    PT.TYPE_ID IS NULL) AND (PT.TYPE_ID <> 400000 OR
                                                                                    PT.TYPE_ID IS NULL)
                                                          GROUP BY P.PO) AS SL ON SL.PO = PO.code LEFT OUTER JOIN
                                                        (SELECT        P.PO, SUM(IIP.QUANTITY) AS quantity
                                                          FROM            prod.PACKAGE AS P LEFT OUTER JOIN
                                                                                    prod.PACKAGE_TYPE AS PT ON PT.ID = P.TYPE_ID LEFT OUTER JOIN
                                                                                    prod.ITEM_IN_PACKAGE AS IIP ON IIP.PACKAGE_ID = P.ID
                                                          WHERE        (PT.TYPE_ID <> 100000) AND (PT.TYPE_ID <> 400000) AND (CAST(P.CREATE_DATE AS DATE) = CAST(GETDATE() AS DATE))
                                                          GROUP BY P.PO) AS SLN ON SLN.PO = PO.code LEFT OUTER JOIN
                                                        (SELECT        P.PO, SUM(IIP.QUANTITY) AS error
                                                          FROM            prod.PACKAGE AS P LEFT OUTER JOIN
                                                                                    prod.PACKAGE_TYPE AS PT ON PT.ID = P.TYPE_ID LEFT OUTER JOIN
                                                                                    prod.ITEM_IN_PACKAGE AS IIP ON IIP.PACKAGE_ID = P.ID
                                                          WHERE        (PT.TYPE_ID = 100000) OR
                                                                                    (PT.TYPE_ID = 400000)
                                                          GROUP BY P.PO) AS ERR ON ERR.PO = PO.code
                          WHERE        (PO.approvedAt IS NOT NULL) AND (PO.endPO = 0) AND (PO.deletedAt IS NULL)) AS x
WHERE        (conThucHien > 0)
ORDER BY approvedAt
GO
/****** Object:  View [dbo].[View_Departments]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Departments]
AS
SELECT        ID AS id, TYPE AS type, PARENT_ID AS parentId, CODE AS code, NAME AS name, TYPE2 AS type2, PACKAGE_TYPE_GROUP_ID AS packageTypeGroupId, MODULE_ID AS moduleId, caLamViec
FROM            base.DEPARTMENT
GO
/****** Object:  View [dbo].[View_getPalletCreated]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SELECT * FROM View_getPalletCreated
-- ORDER BY ID DESC
CREATE   VIEW [dbo].[View_getPalletCreated]
AS
SELECT PLS.ID,PLS.CODE,PLS.CREATE_BY,PLS.CREATE_DATE,PLS.STEP_ID,PLS.STEP_NEXT_ID,P.VERIFY_BY,P.VERIFY_DATE
FROM (
SELECT PL.ID,PL.CODE,PL.CREATE_BY,PL.CREATE_DATE,SOP.ID STEP_OF_PALLET_ID,SOP.STEP_ID,SOP.STEP_NEXT_ID,ROW_NUMBER() OVER(PARTITION BY PL.ID ORDER BY SOP.ID ASC) AS STEP_RANK
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
) PLS
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = PLS.STEP_OF_PALLET_ID
WHERE PLS.STEP_RANK = 1

GO
/****** Object:  View [dbo].[View_getPalletStep]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SELECT * FROM View_getPalletStep
CREATE   VIEW [dbo].[View_getPalletStep]
AS
SELECT PLS.ID,PLS.CODE,PLS.CREATE_BY,PLS.CREATE_DATE,P.ID PACKAGE_ID,P.SOURCE_ID,P.DESTINATION_ID,P.VERIFY_BY,P.VERIFY_DATE,PLS.STEP_RANK
FROM (
SELECT PL.ID,PL.CODE,PL.CREATE_BY,PL.CREATE_DATE,SOP.ID STEP_OF_PALLET_ID,SOP.STEP_ID,SOP.STEP_NEXT_ID,ROW_NUMBER() OVER(PARTITION BY PL.ID ORDER BY SOP.ID ASC) AS STEP_RANK
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
) PLS
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = PLS.STEP_OF_PALLET_ID


GO
/****** Object:  View [dbo].[View_GhiNhanCT]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_GhiNhanCT]
AS
SELECT        iip.PACKAGE_ID, iip.ITEM_ID, iip.QUANTITY, p.ID AS packageId, p.STEP_OF_PALLET_ID, p.SOURCE_ID, p.DESTINATION_ID, p.ITEM_FROM_ID, p.TYPE_ID, p.REMEDIES_ID, p.DESCRIPTION, p.CREATE_BY, p.CREATE_DATE, 
                         p.VERIFY_BY, p.VERIFY_DATE, p.KH_VERIFY_BY, p.KH_VERIFY_DATE, p.PO, po.code, po.parent, po.stepId, po.itemId, po.counts, po.[order], po.time, po.shift, po.week, po.year, po.market, po.ton, po.soLuongUuTien, 
                         po.hanMucTon, po.soLuongCanSanXuat, po.status, po.type, po.root, po.number, po.factor, po.keHoach, po.capPhoi, po.taoPhoi, po.ngayDongGoi, po.thoiGianCho, po.thoiGianBatDau, po.ngayLamViec, po.thoiGianCanSanXuat, 
                         po.thoiGianThucHien, po.caLamViec, po.deletedAt, po.createdAt, po.updatedAt, po.factoryId, po.daNhanTon, po.endPO, po.approvedByAccount, po.approvedAt, po.loiCongDon, po.fromPo, po.xuatTon, po.th, po.ys1a, po.ys1b, 
                         po.ys4, iip.ID
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS p ON p.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                         prod.PO AS po ON po.code = p.PO
WHERE        (p.PO IS NOT NULL) AND (p.TYPE_ID = 100026)
GO
/****** Object:  View [dbo].[View_in_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
				CREATE   VIEW [dbo].[View_in_not_verify]
				AS
				SELECT SOP.STEP_ID,
                SOP.STEP_NEXT_ID,
                SOP.ITEM_ID,
                SOP.PASS,
                PL.ID PALLET_ID,
                PL.CODE PALLET_CODE,
                P.ID PACKAGE_ID,
                P.CREATE_BY,
                P.CREATE_DATE
                FROM dbo.[STEP_OF_PALLET] SOP
                LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                WHERE P.VERIFY_BY IS NULL

GO
/****** Object:  View [dbo].[View_in_not_verify_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
				CREATE   VIEW [dbo].[View_in_not_verify_item]
				AS
				SELECT PL.ID,
				SOP.STEP_NEXT_ID,
                IIP.ITEM_ID,
                IIP.QUANTITY
                FROM dbo.[STEP_OF_PALLET] SOP
                LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                LEFT JOIN dbo.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
                WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [dbo].[View_inNotVerify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[View_inNotVerify]
AS
SELECT SOP.STEP_NEXT_ID AS DENKHO,
PL.ID PALLET_ID,
--PL.CODE PALLET_CODE,
P.ID PACKAGE_ID,
P.CREATE_BY,
P.CREATE_DATE,
P.VERIFY_BY,
P.VERIFY_DATE
FROM dbo.[STEP_OF_PALLET] SOP
LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [dbo].[View_ITEM_IN_PALLET]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ITEM_IN_PALLET]
AS
SELECT        prod.ITEM_IN_PALLET.ITEM_ID, prod.ITEM_IN_PALLET.ID, prod.ITEM_IN_PALLET.PALLET_ID, prod.ITEM_IN_PALLET.QUANTITY, base.ITEM.NAME, base.ITEM.VOLUMN, 
                         prod.ITEM_IN_PALLET.QUANTITY * base.ITEM.VOLUMN AS khoiLuong, base.ITEM.HEIGHT, base.ITEM.WIDTH, base.ITEM.LENGTH
FROM            prod.ITEM_IN_PALLET LEFT OUTER JOIN
                         base.ITEM ON prod.ITEM_IN_PALLET.ITEM_ID = base.ITEM.ID
GO
/****** Object:  View [dbo].[View_ITEM100002]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ITEM100002]
AS
SELECT        base.ITEM.ID, base.ITEM.CODE, base.ITEM.NAME, base.ITEM.LENGTH, base.ITEM.WIDTH, base.ITEM.HEIGHT, base.ITEM.TYPE_ID, base.ITEM.UNIT_ID, base.ITEM.VOLUMN, base.ITEM.WOOD_TYPE_ID, 
                         base.UNIT.NAME AS Expr4, base.ITEM_TYPE.NAME AS Expr8
FROM            base.ITEM INNER JOIN
                         base.UNIT ON base.ITEM.UNIT_ID = base.UNIT.ID INNER JOIN
                         base.ITEM_TYPE ON base.ITEM.TYPE_ID = base.ITEM_TYPE.ID
WHERE        (base.ITEM.FACTORY_ID = 100002)
GO
/****** Object:  View [dbo].[View_ItemInPackages]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ItemInPackages]
AS
SELECT        NULL AS id, x.itemId, x.name, SUM(x.QUANTITY) AS QUANTITY, CONVERT(varchar, x.createdAt, 112) AS createdAt, DATEPART(HOUR, x.createdAt) AS gio, CONVERT(varchar, x.updatedAt, 112) AS updatedAt, x.accountId, 
                         x.accountId2, NULL AS code, x.stepId1, x.stepId2, x.HEIGHT, x.WIDTH, x.LENGTH
FROM            (SELECT        iip.ID, p.ID AS packageId, iip.ITEM_ID AS itemId, T.NAME AS name, T.HEIGHT, T.WIDTH, T.LENGTH, iip.QUANTITY, p.PO AS code, p.CREATE_DATE AS createdAt, p.CREATE_BY AS accountId, 
                                                    p.VERIFY_BY AS accountId2, p.VERIFY_DATE AS updatedAt, p.SOURCE_ID AS stepId1, p.DESTINATION_ID AS stepId2
                          FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                                                    prod.PACKAGE AS p ON p.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                                                    base.ITEM AS T ON T.ID = iip.ITEM_ID
                          WHERE        (p.PO IS NOT NULL) AND (p.TYPE_ID = 100026) AND (p.PO IN
                                                        (SELECT        code
                                                          FROM            prod.PO
                                                          WHERE        (deletedAt IS NULL) AND (endPO = 0) AND (approvedAt IS NOT NULL)))) AS x LEFT OUTER JOIN
                         prod.PO AS p ON x.code = p.code
GROUP BY x.itemId, x.name, CONVERT(varchar, x.createdAt, 112), DATEPART(HOUR, x.createdAt), x.accountId, x.accountId2, x.stepId1, x.stepId2, x.HEIGHT, x.WIDTH, x.LENGTH, CONVERT(varchar, x.updatedAt, 112)
GO
/****** Object:  View [dbo].[View_itemInPalletInKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

									CREATE   VIEW [dbo].[View_itemInPalletInKilnBatch]
									AS
									SELECT PL.ID, IIP.ITEM_ID,IIP.QUANTITY
                                    FROM dbo.[KILN_BATCH] KB
                                    LEFT JOIN dbo.[KILN] K ON K.ID = KB.KILN_ID
									LEFT JOIN dbo.[STEP_OF_PALLET] SOP ON SOP.KILN_BATCH_ID = KB.ID
									LEFT JOIN dbo.PALLET PL ON PL.ID = SOP.PALLET_ID
									LEFT JOIN dbo.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
                                    WHERE KB.TIME_OUT_REAL IS NULL
									AND PL.ID IS NOT NULL
GO
/****** Object:  View [dbo].[View_Items]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Items]
AS
SELECT        ID AS id, CODE AS code, NAME AS name, LENGTH AS length, WIDTH AS width, HEIGHT AS height, TYPE_ID AS typeId, UNIT_ID AS unitId, IMAGE_URL AS imageUrl, CREATE_DATE AS createDate, ACTIVE AS active, 
                         GROUP_ITEM AS groupItem, MODULE_ID AS moduleId, VOLUMN AS volumn, WOOD_TYPE_ID AS woodTypeId, FACTORY_ID AS factoryId, heSo
FROM            base.ITEM
GO
/****** Object:  View [dbo].[View_kilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


									CREATE    VIEW [dbo].[View_kilnBatch]
									AS
									SELECT KB.ID ID,
                                    KB.[YEAR],KB.[WEEK],KB.[NUMBER],
                                    K.ID KILN_ID,
                                    K.CODE KILN_CODE,
                                    K.NAME KILN_NAME,
									K.FACTORY_ID,
                                    KB.TIME_OUT_TARGET,
                                    KB.CREATE_DATE + KB.TIME_OUT_TARGET AS TIME_OUT,
                                    KB.STEP_NEXT_ID,
                                    KB.CREATE_BY,
                                    KB.CREATE_DATE,
                                    KB.[LENGTH],
                                    KB.HEIGHT,
                                    KB.VERIFY,
                                    KB.VERIFY_BY,
                                    KB.HUMIDITY,
                                    KB.[STATE]
                                    FROM dbo.[KILN_BATCH] KB
                                    LEFT JOIN dbo.[KILN] K ON K.ID = KB.KILN_ID
                                    WHERE KB.TIME_OUT_REAL IS NULL

GO
/****** Object:  View [dbo].[View_MaterialInPackage]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_MaterialInPackage]
AS
SELECT        m.ID, m.ITEM_ID, m.QUANTITY, p.DESTINATION_ID, p.SOURCE_ID, p.CREATE_DATE, p.VERIFY_DATE, i.VOLUMN * m.QUANTITY AS khoiLuongNhan
FROM            prod.MATERIALS_IN_PACKAGE AS m LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS ip ON m.ITEM_IN_PACKAGE_ID = ip.ID LEFT OUTER JOIN
                         prod.PACKAGE AS p ON p.ID = ip.PACKAGE_ID LEFT OUTER JOIN
                         base.ITEM AS i ON i.ID = m.ITEM_ID
GO
/****** Object:  View [dbo].[View_not_out]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[View_not_out]
AS
SELECT 
SOP.STEP_ID,
SOP.STEP_NEXT_ID,
SOP.ITEM_ID,
SOP.PASS,
PL.ID PALLET_ID,
PL.CODE PALLET_CODE,
PL.TYPE_ID PALLET_TYPE_ID,
P.ID PACKAGE_ID,
P.CREATE_BY,
P.CREATE_DATE,
P.VERIFY_BY,
P.VERIFY_DATE
FROM dbo.[STEP_OF_PALLET] SOP
LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN dbo.[STEP_OF_PALLET] SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
WHERE P.VERIFY_BY IS NOT NULL -- đã nhận
AND SOPOUT.ID IS NULL -- nhưng chưa xuất

GO
/****** Object:  View [dbo].[View_not_out_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[View_not_out_item]
AS
SELECT PL.ID,
IIP.ITEM_ID,
IIP.QUANTITY,
SOP.STEP_NEXT_ID
FROM dbo.[STEP_OF_PALLET] SOP
LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN dbo.[STEP_OF_PALLET] SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
LEFT JOIN dbo.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
WHERE P.VERIFY_BY IS NOT NULL -- đã nhận
AND SOPOUT.ID IS NULL -- nhưng chưa xuất

GO
/****** Object:  View [dbo].[View_OPENING_STOCK]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_OPENING_STOCK]
AS
SELECT        o.ID, o.DATE, o.MONTH, o.DEPARTMENT_ID, o.ITEM_ID, o.QUANTITY, o.WEEK, o.PO_ID, o.market_code, o.color, o.CREATE_BY, o.createdAt, o.updatedAt, o.nguonPhoi, o.QUANTITY * bi.VOLUMN AS khoiLuongTonDauKy
FROM            prod.OPENING_STOCK AS o LEFT OUTER JOIN
                         base.ITEM AS bi ON o.ITEM_ID = bi.ID
GO
/****** Object:  View [dbo].[View_out_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
					CREATE   VIEW [dbo].[View_out_not_verify]
					AS
					SELECT SOP.STEP_ID,
                    SOP.STEP_NEXT_ID,
                    SOP.ITEM_ID,
                    SOP.PASS,
                    PL.ID PALLET_ID,
                    PL.CODE PALLET_CODE,
                    P.ID PACKAGE_ID,
                    P.CREATE_BY,
                    P.CREATE_DATE
                    FROM dbo.[STEP_OF_PALLET] SOP
                    LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                    LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                    WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [dbo].[View_out_not_verify_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
					CREATE   VIEW [dbo].[View_out_not_verify_item]
					AS
					SELECT PL.ID,
					SOP.STEP_ID,
                    IIP.ITEM_ID,
                    IIP.QUANTITY
                    FROM dbo.[STEP_OF_PALLET] SOP
                    LEFT JOIN dbo.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                    LEFT JOIN dbo.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                    LEFT JOIN dbo.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
                    WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [dbo].[View_PackageDepartment]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_PackageDepartment]
AS
SELECT        i.ID, i.PACKAGE_ID, i.ITEM_ID, i.QUANTITY, i.QUANTITY * bi.VOLUMN AS khoiLuongXuat, p.SOURCE_ID, p.TYPE_ID, p.CREATE_DATE, d.NAME, p.VERIFY_BY, p.VERIFY_DATE, p.KH_VERIFY_BY, p.KH_VERIFY_DATE, p.PO, 
                         d.TYPE, p.DESTINATION_ID, p.ITEM_FROM_ID, p.REMEDIES_ID, p.DESCRIPTION, p.CREATE_BY, p.STEP_OF_PALLET_ID, bi.NAME AS tenSP, i.QUANTITY * bi.VOLUMN AS khoiLuongNhan, i.factoryId, bi.FACTORY_ID, 
                         d.factoryId AS Expr1, p.factoryId AS Expr2
FROM            prod.ITEM_IN_PACKAGE AS i LEFT OUTER JOIN
                         prod.PACKAGE AS p ON i.PACKAGE_ID = p.ID LEFT OUTER JOIN
                         base.DEPARTMENT AS d ON p.DESTINATION_ID = d.ID LEFT OUTER JOIN
                         base.ITEM AS bi ON i.ITEM_ID = bi.ID
GO
/****** Object:  View [dbo].[View_packages_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[View_packages_not_verify]
AS
SELECT ID, SOURCE_ID,DESTINATION_ID,TYPE_ID,CREATE_BY,CREATE_DATE
FROM dbo.[PACKAGE]
WHERE VERIFY_BY IS NULL
GO
/****** Object:  View [dbo].[View_packages_not_verify_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    VIEW [dbo].[View_packages_not_verify_item]
AS
SELECT P.ID PACKAGE_ID,P.DESTINATION_ID,IIP.ITEM_ID,IIP.QUANTITY
FROM dbo.[PACKAGE] P
LEFT JOIN dbo.[ITEM_IN_PACKAGE] IIP ON IIP.PACKAGE_ID = P.ID
WHERE P.VERIFY_BY IS NULL


GO
/****** Object:  View [dbo].[View_PackageVolumn]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_PackageVolumn]
AS
SELECT        m.ITEM_IN_PACKAGE_ID AS ID, SUM(i.VOLUMN * m.QUANTITY) AS khoiLuongNhan, SUM(m.QUANTITY) AS soLuongNhan
FROM            prod.MATERIALS_IN_PACKAGE AS m LEFT OUTER JOIN
                         base.ITEM AS i ON m.ITEM_ID = i.ID
GROUP BY m.ITEM_IN_PACKAGE_ID
GO
/****** Object:  View [dbo].[View_PALLET_CHO_XAY]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_PALLET_CHO_XAY]
AS
SELECT DISTINCT 
                         prod.PALLET.ID, prod.PALLET.CODE, prod.PALLET.YEAR, prod.PALLET.WEEK, prod.PALLET.CREATE_BY, prod.PALLET.CREATE_DATE, base.ACCOUNT.LAST_NAME, prod.PALLET.factoryId AS Expr1, base.ACCOUNT.factoryId, 
                         prod.PACKAGE.VERIFY_BY, prod.PACKAGE_TYPE.NAME
FROM            prod.PALLET LEFT OUTER JOIN
                             (SELECT DISTINCT *
                               FROM            (SELECT DISTINCT PALLET_ID, ID, ROW_NUMBER() OVER (PARTITION BY PALLET_ID
                                                         ORDER BY ID) num
                               FROM            prod.STEP_OF_PALLET) s
WHERE        s.num = 1) AS ST ON ST.PALLET_ID = prod.PALLET.ID LEFT OUTER JOIN
prod.PACKAGE ON prod.PACKAGE.STEP_OF_PALLET_ID = ST.ID LEFT OUTER JOIN
base.ACCOUNT ON prod.PALLET.CREATE_BY = base.ACCOUNT.ID LEFT JOIN
prod.PACKAGE_TYPE ON prod.PACKAGE.TYPE_ID = prod.PACKAGE_TYPE.ID
GO
/****** Object:  View [dbo].[View_PalletInKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

									CREATE   VIEW [dbo].[View_PalletInKilnBatch]
									AS
									SELECT KB.ID KILN_BATCH_ID,PL.ID,PL.CODE
                                    FROM dbo.[KILN_BATCH] KB
                                    LEFT JOIN dbo.[KILN] K ON K.ID = KB.KILN_ID
									LEFT JOIN dbo.[STEP_OF_PALLET] SOP ON SOP.KILN_BATCH_ID = KB.ID
									LEFT JOIN dbo.PALLET PL ON PL.ID = SOP.PALLET_ID
                                    WHERE KB.TIME_OUT_REAL IS NULL
									AND PL.ID IS NOT NULL
GO
/****** Object:  View [dbo].[View_PhoiNhan]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[View_PhoiNhan]
AS
select ITEM_ID, stepId, number, sum(quantity) as quantity from (
select iip.ITEM_ID, p.DESTINATION_ID as stepId, po.number, sum(iip.QUANTITY) as quantity
                from prod.ITEM_IN_PACKAGE iip
                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
                    left join prod.PO po on po.code = p.PO
                where p.VERIFY_DATE is not null and po.number is not null
                group by iip.ITEM_ID, p.DESTINATION_ID, po.number

            UNION

                select m.ITEM_ID,p.SOURCE_ID as stepId, po.number, -sum(m.QUANTITY) as quantity
                from prod.MATERIALS_IN_PACKAGE m
                    left join prod.ITEM_IN_PACKAGE iip on m.ITEM_IN_PACKAGE_ID = iip.ID
                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
                    left join prod.PO po on po.code = p.PO
                where po.number is not null
                group by m.ITEM_ID, p.SOURCE_ID, po.number
) as T
group by ITEM_ID, stepId, number
GO
/****** Object:  View [dbo].[View_raw_data]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_raw_data]
AS
SELECT        P.ID, GD.[YEAR] N'Năm', (GD.[WEEK] -1) N'Tuần', po.number, GD.[WEEK_DAY] N'Thứ', S.ID 'DEPARTMENT_ID', S.NAME N'Tổ', D .NAME N'Nơi xuất', PL.CODE N'Mã pallet', SOP.PASS N'Đạt', SOP.NOT_PASS N'Không đạt', 
                         I.[NAME] N'Chi tiết/cụm', U.[NAME] unit, IIP.QUANTITY N'Số lượng', CB.LAST_NAME N'Người tạo', P.CREATE_DATE N'Ngày tạo', VB.LAST_NAME N'Người nhận', P.VERIFY_DATE N'Ngày nhận', i.HEIGHT N'Dầy', i.WIDTH N'Rộng', 
                         i.[LENGTH] N'Dài', po.keHoach
FROM            prod.PACKAGE P LEFT JOIN
                         prod.PO po ON po.code = p.PO LEFT JOIN
                         base.DEPARTMENT S ON S.ID = P.SOURCE_ID LEFT JOIN
                         base.DEPARTMENT D ON D .ID = P.DESTINATION_ID LEFT JOIN
                         prod.STEP_OF_PALLET SOP ON SOP.ID = P.STEP_OF_PALLET_ID LEFT JOIN
                         prod.PALLET PL ON PL.ID = SOP.PALLET_ID LEFT JOIN
                         prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID LEFT JOIN
                         base.ITEM I ON I.ID = IIP.ITEM_ID LEFT JOIN
                         base.UNIT U ON U.ID = I.UNIT_ID LEFT JOIN
                         base.ACCOUNT CB ON CB.ID = P.CREATE_BY LEFT JOIN
                         base.ACCOUNT VB ON VB.ID = P.VERIFY_BY LEFT JOIN
                         base.GLOBAL_DATE GD ON GD.[DATE] = CAST(P.CREATE_DATE AS DATE)
WHERE        P.TYPE_ID = 100026
GO
/****** Object:  View [dbo].[View_raw_nhap_ton]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_raw_nhap_ton]
AS
SELECT        P.ID, GD.[YEAR] N'Năm', GD.[WEEK] N'Tuần', GD.[WEEK_DAY] N'Thứ', D .ID 'DEPARTMENT_ID', D .NAME N'Tổ', D .NAME N'Nơi xuất', I.[NAME] N'Chi tiết/cụm', I.LENGTH, I.WIDTH, I.HEIGHT, nguonPhoi N'Nguồn Phôi', U.[NAME] unit, 
                         D1.NAME noiden, P.QUANTITY N'Số lượng', CB.LAST_NAME N'Người nhập', P.createdAt N'Ngày giờ nhập',P.DATE,P.description
FROM            prod.OPENING_STOCK P LEFT JOIN
                         base.DEPARTMENT D ON D .ID = P.DEPARTMENT_ID LEFT JOIN
                         base.DEPARTMENT D1 ON D1.ID = P.DESTINATION_ID LEFT JOIN
                         base.ITEM I ON I.ID = P.ITEM_ID LEFT JOIN
                         base.UNIT U ON U.ID = I.UNIT_ID LEFT JOIN
                         base.ACCOUNT CB ON CB.ID = P.CREATE_BY LEFT JOIN
                         base.GLOBAL_DATE GD ON GD.[DATE] = CAST(P.createdAt AS DATE)
GO
/****** Object:  View [dbo].[View_Routing]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Routing]
AS
SELECT        r.ID, i.CODE, r.ITEM_ID, i.NAME, d.NAME AS Xuong, r.[ORDER], r.factoryId
FROM            prod.ROUTING AS r LEFT OUTER JOIN
                         base.DEPARTMENT AS d ON d.ID = r.STEP_ID LEFT OUTER JOIN
                         base.ITEM AS i ON i.ID = r.ITEM_ID
GO
/****** Object:  View [dbo].[View_ROUTINGD]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  CREATE VIEW [dbo].[View_ROUTINGD]
  AS
  SELECT       R.ID, R.ITEM_ID AS itemId, R.STEP_ID AS stepId, R.[ORDER] as [order], R.thoiGianThucHien, D.caLamViec, R.factoryId
  FROM            prod.ROUTING AS R LEFT OUTER JOIN
                           base.DEPARTMENT AS D ON R.STEP_ID = D.ID
    
GO
/****** Object:  View [dbo].[View_Routings]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_Routings]
AS
SELECT        ID AS id, ITEM_ID AS itemId, STEP_ID AS stepId, [ORDER] AS [order]
FROM            prod.ROUTING
GO
/****** Object:  View [dbo].[View_SanLuong]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_SanLuong]
AS
SELECT        TOP (100) PERCENT iip.ID, iip.ITEM_ID AS itemId, iip.QUANTITY, i.NAME AS itemName, i.LENGTH, i.WIDTH, i.HEIGHT, i.VOLUMN * iip.QUANTITY AS tongKL, d.NAME AS departmentName, m.NAME AS sanPham, i.VOLUMN, 
                         pa.CREATE_DATE AS createDate, po.factoryId AS Expr2, pa.factoryId AS Expr1, po.factoryId, m.factoryId AS Expr3, d.factoryId AS Expr4, i.FACTORY_ID, d.ID AS idDepartment, d.ID AS departmentId, pa.VERIFY_BY
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS pa ON iip.PACKAGE_ID = pa.ID LEFT OUTER JOIN
                         prod.PO AS po ON pa.PO = po.code LEFT OUTER JOIN
                         base.DEPARTMENT AS d ON d.ID = pa.SOURCE_ID LEFT OUTER JOIN
                         base.MARKET AS m ON m.CODE = po.root LEFT OUTER JOIN
                         base.ITEM AS i ON i.ID = iip.ITEM_ID
WHERE        (po.deletedAt IS NULL) AND (po.root IS NOT NULL)
ORDER BY createDate
GO
/****** Object:  View [dbo].[View_SP_YS1A]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_SP_YS1A]
AS
with temp(MATERIALS_ID,ITEM_ID)
as
(SELECT        MATERIALS_ID, ITEM_ID
FROM            prod.BOM
WHERE        (factoryId = 100003)
UNION ALL
SELECT        b.MATERIALS_ID, a.ITEM_ID
FROM            temp AS a INNER JOIN
                         prod.BOM AS b ON a.MATERIALS_ID = b.ITEM_ID
WHERE        (b.factoryId = 100003))
    SELECT DISTINCT I.NAME, I.ID AS ITEM_ID, I1.NAME AS paren, I1.ID AS paren_id, D .NAME AS congdoan, R1.STEP_ID, R1.factoryId
     FROM            prod.ROUTING AS R LEFT OUTER JOIN
                              base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                              temp AS te ON te.ITEM_ID = I1.ID LEFT OUTER JOIN
                              base.ITEM AS I ON I.ID = te.MATERIALS_ID LEFT OUTER JOIN
                              prod.ROUTING AS R1 ON I.ID = R1.ITEM_ID AND R1.factoryId = 100003 LEFT OUTER JOIN
                              base.DEPARTMENT AS D ON D .ID = R1.STEP_ID
     WHERE        (R.STEP_ID IN (102463, 102487, 102488) OR
                              (R.STEP_ID in (102352,102439) AND R.[ORDER] = 1)) AND (I.NAME IS NOT NULL) AND (R.factoryId = 100003)
UNION ALL
SELECT DISTINCT I1.NAME NAME, R.ITEM_ID, I1.NAME paren, R.STEP_ID paren_id, D .NAME congdoan, R.STEP_ID, R.factoryId
FROM            prod.ROUTING AS R LEFT OUTER JOIN
                         base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D .ID = R.STEP_ID
WHERE        R.STEP_ID in (102352,102439) AND R.[ORDER] = 1 AND (R.factoryId = 100003)
GO
/****** Object:  View [dbo].[View_SP_YS1B]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_SP_YS1B]
AS
WITH temp(MATERIALS_ID,ITEM_ID)
        as
		(SELECT        MATERIALS_ID, ITEM_ID
FROM            prod.BOM
WHERE        (factoryId = 100004)
UNION ALL
SELECT        b.MATERIALS_ID, a.ITEM_ID
FROM            temp AS a INNER JOIN
                         prod.BOM AS b ON a.MATERIALS_ID = b.ITEM_ID
WHERE        (b.factoryId = 100004))
    SELECT        I.NAME, I.ID AS ITEM_ID, I1.NAME AS paren, I1.ID AS paren_id, D .NAME AS congdoan, R1.STEP_ID, R1.factoryId
     FROM            prod.ROUTING AS R LEFT OUTER JOIN
                              base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                              temp AS te ON te.ITEM_ID = I1.ID LEFT OUTER JOIN
                              base.ITEM AS I ON I.ID = te.MATERIALS_ID LEFT OUTER JOIN
                              prod.ROUTING AS R1 ON I.ID = R1.ITEM_ID AND R1.factoryId = 100004 LEFT OUTER JOIN
                              base.DEPARTMENT AS D ON D .ID = R1.STEP_ID
     WHERE        ((R.STEP_ID IN (102363) AND (R.[ORDER] = 1)) OR (R.STEP_ID IN (102454) AND (R.[ORDER] = 3))) AND (I.NAME IS NOT NULL) AND (R.factoryId = 100004)
UNION ALL
SELECT DISTINCT I1.NAME NAME, R.ITEM_ID, I1.NAME paren, R.STEP_ID paren_id, D .NAME congdoan, R.STEP_ID, R.factoryId
FROM            prod.ROUTING AS R LEFT OUTER JOIN
                         base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D .ID = R.STEP_ID
WHERE        ((R.STEP_ID IN (102363) AND (R.[ORDER] = 1))OR (R.STEP_ID IN (102363) AND (R.[ORDER] = 2 and R.ITEM_ID = 124096))) AND (R.factoryId = 100004) 
GO
/****** Object:  View [dbo].[View_SP_YS4]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_SP_YS4]
AS
WITH temp(MATERIALS_ID,ITEM_ID)
as
(SELECT        MATERIALS_ID, ITEM_ID
FROM            prod.BOM
WHERE        (factoryId = 100005)
UNION ALL
SELECT        b.MATERIALS_ID, a.ITEM_ID
FROM            temp AS a INNER JOIN
                         prod.BOM AS b ON a.MATERIALS_ID = b.ITEM_ID
WHERE        (b.factoryId = 100005))
    SELECT        I.NAME, I.ID AS ITEM_ID, I1.NAME AS paren, I1.ID AS paren_id, D .NAME AS congdoan, R1.STEP_ID,R1.factoryId
     FROM            prod.ROUTING AS R LEFT OUTER JOIN
                              base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                              temp AS te ON te.ITEM_ID = I1.ID LEFT OUTER JOIN
                              base.ITEM AS I ON I.ID = te.MATERIALS_ID LEFT OUTER JOIN
                              prod.ROUTING AS R1 ON I.ID = R1.ITEM_ID AND R1.factoryId = 100005 LEFT OUTER JOIN
                              base.DEPARTMENT AS D ON D .ID = R1.STEP_ID
     WHERE        (R.STEP_ID IN (102460)) AND (I.NAME IS NOT NULL)  AND (R.factoryId = 100005)
UNION ALL
SELECT DISTINCT I1.NAME NAME, R.ITEM_ID, I1.NAME paren, R.STEP_ID paren_id, D .NAME congdoan, R.STEP_ID,R.factoryId
FROM            prod.ROUTING AS R LEFT OUTER JOIN
                         base.ITEM AS I1 ON I1.ID = R.ITEM_ID LEFT OUTER JOIN
                         base.DEPARTMENT AS D ON D .ID = R.STEP_ID
WHERE        (R.STEP_ID IN (102460))  AND (R.factoryId = 100005)
GO
/****** Object:  View [dbo].[View_ThongTinTruyNguyen]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_ThongTinTruyNguyen]
AS
SELECT        p.PO, I.ID AS suppliesId, I.NAME AS supplies, v.ID AS vendorId, v.NAME AS vendor, p.QUANTITY, p.PARCEL, p.CREATE_DATE AS createDate, p.ID, po.number, d.NAME AS departmentName, i2.NAME AS sanPham, i2.HEIGHT, 
                         i2.WIDTH, i2.LENGTH, i2.VOLUMN, p.factoryId, I.FACTORY_ID, po.factoryId AS Expr1, d.factoryId AS Expr2, i2.FACTORY_ID AS Expr3, v.factoryId AS Expr4
FROM            prod.PALLET_SUPPLIES AS p LEFT OUTER JOIN
                         base.VENDOR AS v ON p.VENDOR_ID = v.ID LEFT OUTER JOIN
                         base.ITEM AS I ON I.ID = p.SUPPLIES_ID LEFT OUTER JOIN
                         prod.PO AS po ON po.code = p.PO LEFT OUTER JOIN
                         base.DEPARTMENT AS d ON d.ID = po.stepId LEFT OUTER JOIN
                         base.ITEM AS i2 ON i2.ID = po.itemId
GO
/****** Object:  View [dbo].[View_TongGhiNhanSL]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[View_TongGhiNhanSL]
AS
SELECT        mip.ITEM_ID AS itemId, - mip.QUANTITY AS quantity, p.SOURCE_ID AS stepId, p.CREATE_DATE AS createdAt, p.VERIFY_DATE AS updatedAt
FROM            prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
                         prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
                         prod.PACKAGE AS p ON p.ID = iip.PACKAGE_ID
WHERE        (p.PO IS NOT NULL) AND (p.VERIFY_DATE IS NOT NULL) AND (iip.ITEM_ID IS NOT NULL)

union all

SELECT        iip.ITEM_ID AS itemId, iip.QUANTITY AS quantity, p.DESTINATION_ID AS stepId, p.CREATE_DATE AS createdAt, p.VERIFY_DATE AS updatedAt
FROM            prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
                         prod.PACKAGE AS p ON p.ID = iip.PACKAGE_ID
WHERE        (p.PO IS NOT NULL) AND (p.VERIFY_DATE IS NOT NULL) AND (iip.ITEM_ID IS NOT NULL)
GO
/****** Object:  View [nlg].[View_PHIEUNHAPKHO_DT]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [nlg].[View_PHIEUNHAPKHO_DT]
AS
SELECT        pnk.ID, pnk.SOPHIEUNHAP, pnk.DAY, pnk.RONG, pnk.CAO, pnk.SOBO, pnk.SOTHANH_BO, pnk.NOTE, pnk.CREATED_AT, pnk.CREATED_BY, pnk.DEL_FLAG, pnk.QC_INSPECTOR, pnk.DELAI, pnk.SAMPLEQTY, pnk.UPDATE_BY, 
                         pnk.UPDATED_AT, pnk.QTY, pnk.MANVL, pnk.DONGIA_CTY, pnk.DONGIA_LOAI, pnk.NOTEHACAP, pnk.CODE, pnk.KLQC, pnk.DONGIA_TB, pnk.CODENHOM, pnk.SOPHIEUTRAVE, pnk.OVER_PLAN, pnk.khacKho, pn.MAKHO, 
                         pn.NHOMSP, pn.MALOGONHAP, pn.BIENSOXE, pn.ALLOWMODIFY, pn.MANCC, pn.ALLOWHACAP, pn.DONGIATB, pn.ALLOWTINHTIEN, pn.QC_STAFF, pn.XUONGXENANG, pn.ACTUALDATE
FROM            nlg.PHIEUNHAPKHO_DT AS pnk LEFT OUTER JOIN
                         nlg.PHIEUNHAPKHO AS pn ON pn.SOPHIEU = pnk.SOPHIEUNHAP
WHERE        (pnk.CREATED_AT > '20200901') AND (pnk.khacKho = 1) AND (pnk.DELAI = N'N') AND (pnk.DEL_FLAG = N'N')
GO
/****** Object:  View [nlg].[View_PLAN_NLG]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [nlg].[View_PLAN_NLG]
AS
SELECT        nlg.PLAN_NLG.ID, nlg.PLAN_NLG.CODE, nlg.PLAN_NLG.MANCC, nlg.PLAN_NLG.PLANQTY, nlg.PLAN_NLG.DEL_FLAG, nlg.PLAN_NLG.CREATE_BY, nlg.PLAN_NLG.CREATED_AT, nlg.GROUP_CODE.NAME AS QUYCACH, 
                         nlg.PLAN_NLG.GROUP_CODE, nlg.PLAN_NLG.KHO
FROM            nlg.PLAN_NLG INNER JOIN
                         nlg.PROVIDERS ON nlg.PROVIDERS.CODE = nlg.PLAN_NLG.MANCC INNER JOIN
                         nlg.GROUP_CODE ON nlg.GROUP_CODE.ID = nlg.PLAN_NLG.GROUP_CODE
WHERE        (nlg.PLAN_NLG.DEL_FLAG = 'N') AND (nlg.PLAN_NLG.CREATED_AT > '20200901')
GO
/****** Object:  View [prod].[View_in_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    VIEW [prod].[View_in_not_verify]
AS
SELECT SOP.STEP_ID,
SOP.STEP_NEXT_ID,
SOP.ITEM_ID,
SOP.PASS,
PL.ID PALLET_ID,
PL.CODE PALLET_CODE,
P.ID PACKAGE_ID,
P.CREATE_BY,
P.CREATE_DATE
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [prod].[View_in_not_verify_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [prod].[View_in_not_verify_item]
AS
SELECT PL.ID,
SOP.STEP_NEXT_ID,
IIP.ITEM_ID,
IIP.QUANTITY
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN prod.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [prod].[View_itemInPalletInKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    VIEW [prod].[View_itemInPalletInKilnBatch]
AS
SELECT PL.ID, IIP.ITEM_ID,IIP.QUANTITY
FROM prod.[KILN_BATCH] KB
LEFT JOIN prod.[KILN] K ON K.ID = KB.KILN_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOP ON SOP.KILN_BATCH_ID = KB.ID
LEFT JOIN prod.PALLET PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN prod.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
WHERE KB.TIME_OUT_REAL IS NULL
AND PL.ID IS NOT NULL
GO
/****** Object:  View [prod].[View_kilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT * FROM prod.[View_kilnBatch]


CREATE    VIEW [prod].[View_kilnBatch]
AS
SELECT A.ID,
'' 'WEEK',
'' NUMBER,
CASE
	WHEN A.[WEEK] < 10 AND A.NUMBER < 10 THEN CONCAT (A.[YEAR],'.0',A.[WEEK],'.0',A.[NUMBER])
	WHEN A.[WEEK] < 10 AND A.NUMBER > 10 THEN CONCAT (A.[YEAR],'.0',A.[WEEK],'.',A.[NUMBER])
	WHEN A.[WEEK] > 10 AND A.NUMBER < 10 THEN CONCAT (A.[YEAR],'.',A.[WEEK],'.0',A.[NUMBER])
	WHEN A.[WEEK] > 10 AND A.NUMBER > 10 THEN CONCAT (A.[YEAR],'.',A.[WEEK],'.',A.[NUMBER])
	ELSE CONCAT (A.[YEAR],'.',A.[WEEK],'.',A.[NUMBER])
END AS 'YEAR',
A.KILN_ID,A.KILN_CODE,A.KILN_NAME,A.FACTORY_ID,A.TIME_OUT_TARGET,A.TIME_OUT,A.STEP_NEXT_ID,A.CREATE_BY,A.CREATE_DATE,A.[LENGTH],A.HEIGHT,A.VERIFY,A.VERIFY_BY,A.HUMIDITY,A.[STATE],A.[TYPE],A.[STATUS],SUM(A.MM3)* 10e-10 TOTAL_M3
FROM (
    SELECT KB.ID ID,
    KB.[YEAR],KB.[WEEK],KB.[NUMBER],
    K.ID KILN_ID,
    K.CODE KILN_CODE,
    K.NAME KILN_NAME,
    K.FACTORY_ID,
    KB.TIME_OUT_TARGET,
    KB.CREATE_DATE + KB.TIME_OUT_TARGET AS TIME_OUT,
    KB.STEP_NEXT_ID,
    KB.CREATE_BY,
    KB.CREATE_DATE,
    KB.[LENGTH],
    KB.HEIGHT,
    KB.VERIFY,
    KB.VERIFY_BY,
    KB.HUMIDITY,
    KB.[STATE],
	KB.[TYPE],
	KB.[STATUS],
    (((I.LENGTH * I.WIDTH * I.HEIGHT) * IIP.QUANTITY)) MM3
    FROM prod.[KILN_BATCH] KB
    LEFT JOIN prod.[KILN] K ON K.ID = KB.KILN_ID
    LEFT JOIN prod.STEP_OF_PALLET SOP ON SOP.KILN_BATCH_ID = KB.ID
    LEFT JOIN prod.PALLET PL ON PL.ID = SOP.PALLET_ID
    LEFT JOIN prod.ITEM_IN_PALLET IIP ON IIP.PALLET_ID = PL.ID
    LEFT JOIN base.ITEM I ON I.ID = IIP.ITEM_ID
    WHERE KB.TIME_OUT_REAL IS NULL
) A
GROUP BY 
A.ID,A.[YEAR],A.WEEK,A.NUMBER,A.KILN_ID,A.KILN_CODE,A.KILN_NAME,A.FACTORY_ID,A.TIME_OUT_TARGET,A.TIME_OUT,A.STEP_NEXT_ID,A.CREATE_BY,A.CREATE_DATE,A.[LENGTH],A.[HEIGHT],A.VERIFY,A.VERIFY_BY,A.HUMIDITY,A.[STATE],A.[TYPE],A.[STATUS]




GO
/****** Object:  View [prod].[View_not_out]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    VIEW [prod].[View_not_out]
AS
SELECT 
SOP.STEP_ID,
SOP.STEP_NEXT_ID,
SOP.ITEM_ID,
SOP.PASS,
PL.ID PALLET_ID,
PL.CODE PALLET_CODE,
PL.TYPE_ID PALLET_TYPE_ID,
P.ID PACKAGE_ID,
P.CREATE_BY,
P.CREATE_DATE,
P.VERIFY_BY,
P.VERIFY_DATE
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
WHERE P.VERIFY_BY IS NOT NULL -- đã nhận
AND SOPOUT.ID IS NULL -- nhưng chưa xuất
--AND  SOP.STEP_NEXT_ID = 100204
GO
/****** Object:  View [prod].[View_not_out_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [prod].[View_not_out_item]
AS
SELECT PL.ID,
IIP.ITEM_ID,
IIP.QUANTITY,
SOP.STEP_NEXT_ID
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
LEFT JOIN prod.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
WHERE P.VERIFY_BY IS NOT NULL -- đã nhận
AND SOPOUT.ID IS NULL -- nhưng chưa xuất
GO
/****** Object:  View [prod].[View_out_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
					CREATE   VIEW [prod].[View_out_not_verify]
					AS
					SELECT SOP.STEP_ID,
                    SOP.STEP_NEXT_ID,
                    SOP.ITEM_ID,
                    SOP.PASS,
                    PL.ID PALLET_ID,
                    PL.CODE PALLET_CODE,
                    P.ID PACKAGE_ID,
                    P.CREATE_BY,
                    P.CREATE_DATE
                    FROM prod.[STEP_OF_PALLET] SOP
                    LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                    LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                    WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [prod].[View_out_not_verify_item]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
					CREATE   VIEW [prod].[View_out_not_verify_item]
					AS
					SELECT PL.ID,
					SOP.STEP_ID,
                    IIP.ITEM_ID,
                    IIP.QUANTITY
                    FROM prod.[STEP_OF_PALLET] SOP
                    LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
                    LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
                    LEFT JOIN prod.[ITEM_IN_PALLET] IIP ON IIP.PALLET_ID = PL.ID
                    WHERE P.VERIFY_BY IS NULL
GO
/****** Object:  View [prod].[View_packages_not_verify]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [prod].[View_packages_not_verify]
AS
SELECT ID, SOURCE_ID,DESTINATION_ID,TYPE_ID,CREATE_BY,CREATE_DATE
FROM prod.[PACKAGE]
WHERE VERIFY_BY IS NULL
GO
/****** Object:  View [prod].[View_PalletInKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    VIEW [prod].[View_PalletInKilnBatch]
AS
SELECT KB.ID KILN_BATCH_ID,PL.ID,PL.CODE
FROM prod.[KILN_BATCH] KB
LEFT JOIN prod.[KILN] K ON K.ID = KB.KILN_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOP ON SOP.KILN_BATCH_ID = KB.ID
LEFT JOIN prod.PALLET PL ON PL.ID = SOP.PALLET_ID
WHERE KB.TIME_OUT_REAL IS NULL
AND PL.ID IS NOT NULL
GO
/****** Object:  StoredProcedure [dbo].[KiemTraTonTaiTo]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[KiemTraTonTaiTo]
	-- Add the parameters for the stored procedure here
	@FROM_ID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select I.Id itemId,
    I.CODE itemCode,
    I.NAME itemName,
    I.LENGTH itemLenght,
    I.WIDTH itemWidth,
    I.HEIGHT itemHeight,
    I.UNIT_ID, ton.ton from (
      select ITEM_ID itemId, SUM(quantity) as ton
          from (
                    select iip.ITEM_ID, sum(iip.QUANTITY) as quantity
              from prod.ITEM_IN_PACKAGE iip
                left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
                left join prod.PO po on po.code = p.PO
              where DESTINATION_ID = @FROM_ID and p.VERIFY_DATE is not null and p.TYPE_ID = 100026 and p.PO is not null
        and po.endPO = 0 and po.approvedAt is not null and po.deletedAt is null
              group by iip.ITEM_ID
    
            UNION
    
              select m.ITEM_ID, -sum(m.QUANTITY) as quantity
              from prod.MATERIALS_IN_PACKAGE m
                left join prod.ITEM_IN_PACKAGE iip on m.ITEM_IN_PACKAGE_ID = iip.ID
                left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
                left join prod.PO po on po.code = p.PO
              where SOURCE_ID = @FROM_ID and p.PO is not null 
        and po.endPO = 0 and po.approvedAt is not null and po.deletedAt is null
              group by m.ITEM_ID
          ) as x
          group by ITEM_ID
    ) ton
    
    left join base.ITEM i on i.ID = ton.itemId
	where ton.ton > 0
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_addEvent]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_addEvent]
@CHANNEL NVARCHAR(200),
@MESSAGE NVARCHAR(MAX)
AS
BEGIN
SET XACT_ABORT ON
BEGIN TRANSACTION
	DECLARE @NO INT
	DECLARE @GUID uniqueidentifier = NEWID()

	SELECT TOP(1) @NO = [NO]
	FROM app.[EVENT]
	WHERE CAST(CREATE_DATE AS DATE) = CAST(GETDATE() AS DATE)
	AND CHANNEL = @CHANNEL
	ORDER BY ID DESC

	IF(@NO IS NULL)
		BEGIN
			SET @NO = 0
		END
	SET @NO = @NO + 1


	INSERT INTO app.[EVENT] ([GUID],[NO],[CHANNEL], [MESSAGE])
	VALUES (@GUID,@NO,@CHANNEL,@MESSAGE)


	SELECT @NO AS 'no'
	FROM app.[EVENT]
	WHERE [GUID] = @GUID
COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_CheckSexistOfDepartment]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<HTHIEU>
-- Create date: <2021-03-25>
-- Description:	<lấy báo cáo sản lượng ghi nhận tuần - query tồn tại tổ theo tuần>
-- =============================================
CREATE PROCEDURE [dbo].[Proc_CheckSexistOfDepartment]
	@fromDate nvarchar(30),
	@fromTo nvarchar(30),
	@week nvarchar(30),
	@year nvarchar(30),
	@departmentId nvarchar(30)
AS
BEGIN
	SET NOCOUNT ON;
	WITH temp(id,NAME)
                as (
                        Select id,NAME
                        From base.DEPARTMENT
                        Where ID = @departmentId
                        Union All
                        Select d.ID,d.NAME
                        From temp as a, base.DEPARTMENT as d
                        Where a.id = d.PARENT_ID
                )
                
	select distinct [ton],[departmentId],
	[itemId],[ten san pham], [item_parent], [KeHoach],[LENGTH],[WIDTH],[HEIGHT],
	[thu2],[thu3],[thu4],[thu5],[thu6],[thu7],[cn],volumn,[WEEK_PO],[WEEK_PERFORM],UNIT_ID,departmentName,null as total,null as conPhaiThucHien, null as totalM3
from 
(
select distinct isnull(ad.ton,0) as[ton],ad.DEPARTMENT_ID as[departmentId],ib.[name] as [item_parent],p.keHoach as [KeHoach], p.week as[WEEK_PO],DATEPART(WEEK,pg.CREATE_DATE) as [WEEK_PERFORM],
i.HEIGHT as [HEIGHT],i.WIDTH as [WIDTH],i.LENGTH as [LENGTH],
case	
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 2 then 'Thu2'
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 3 then 'Thu3'
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 4 then 'Thu4'
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 5 then 'Thu5'
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 6 then 'Thu6'
	when DATEPART(WEEKDAY,pg.CREATE_DATE) = 7 then 'Thu7'
	else 'cn' 
end as [thu],pgi.QUANTITY as [qty],pgi.ITEM_ID as [itemId],i.[NAME] as [ten san pham],i.[name],i.volumn,i.UNIT_ID,ad.NAME  departmentName
from prod.PACKAGE as pg
inner join prod.PO p on p.code = pg.PO
inner join prod.ITEM_IN_PACKAGE as pgi on pgi.PACKAGE_ID = pg.ID
inner join base.ITEM as i on i.id = pgi.ITEM_ID
full outer join(
	     select CASE WHEN OS.QUANTITY IS NULL THEN XN.NHAP1 - XN.XUAT1
                ELSE OS.QUANTITY+XN.NHAP1 - XN.XUAT1
            END AS TONDAUKY, 
            CASE WHEN OS.QUANTITY IS NULL THEN XN.NHAP - XN.XUAT + XN.NHAP1 - XN.XUAT1
                ELSE XN.NHAP - XN.XUAT + XN.NHAP1 - XN.XUAT1 + OS.QUANTITY
                END AS TON,
				xn.ITEM_ID,
				D.NAME,
				xn.DEPARTMENT_ID
            FROM (
                SELECT
                    CASE WHEN X.DEPARTMENT_ID IS NOT NULL THEN X.DEPARTMENT_ID
                        ELSE N.DEPARTMENT_ID
                    END AS DEPARTMENT_ID,
                    CASE WHEN X.ITEM_ID IS NOT NULL THEN X.ITEM_ID
                        ELSE N.ITEM_ID 
                    END AS ITEM_ID,
                    CASE WHEN X.XUAT IS NULL THEN 0
                        ELSE X.XUAT
                    END AS XUAT,
					  CASE WHEN X1.XUAT1 IS NULL THEN 0
                        ELSE X1.XUAT1
                    END AS XUAT1,
                    CASE WHEN N.NHAP IS NULL THEN 0
                        ELSE N.NHAP
                    END AS NHAP,
					  CASE WHEN N1.NHAP1 IS NULL THEN 0
                        ELSE N1.NHAP1
                    END AS NHAP1
                FROM (
                -- Xuất nvl
                SELECT DEPARTMENT_ID,ITEM_ID,SUM(QUANTITY) XUAT
                FROM (
                    SELECT P.SOURCE_ID  DEPARTMENT_ID, MIP.ITEM_ID, MIP.QUANTITY
                    FROM prod.PACKAGE P
                    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                    LEFT JOIN prod.MATERIALS_IN_PACKAGE MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
                    WHERE DATEPART(WEEK,P.CREATE_DATE)  = 11 AND DATEPART(YEAR,P.CREATE_DATE)  = 2021 AND P.TYPE_ID = 100026
                ) L0
                GROUP BY L0.DEPARTMENT_ID, L0.ITEM_ID
                ) X
				
					
                FULL OUTER JOIN (
                -- Nhập nvl
                SELECT DEPARTMENT_ID,ITEM_ID,SUM(QUANTITY) NHAP
                FROM (
                    SELECT CONVERT(DATE,P.CREATE_DATE) DATE,P.DESTINATION_ID DEPARTMENT_ID, IIP.ITEM_ID,IIP.QUANTITY
                    FROM prod.PACKAGE P
                    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                    WHERE DATEPART(WEEK,P.VERIFY_DATE) = 11 AND DATEPART(YEAR,P.VERIFY_DATE)  = 2021 AND  P.TYPE_ID = 100026 AND P.VERIFY_DATE is not null
                ) L0
                GROUP BY L0.DEPARTMENT_ID, L0.ITEM_ID
                ) N ON N.DEPARTMENT_ID = X.DEPARTMENT_ID AND N.ITEM_ID = X.ITEM_ID
					LEFT JOIN 
			 (SELECT DEPARTMENT_ID,ITEM_ID,SUM(QUANTITY) NHAP1
                FROM (
                    SELECT CONVERT(DATE,P.CREATE_DATE) DATE,P.DESTINATION_ID DEPARTMENT_ID, IIP.ITEM_ID,IIP.QUANTITY
                    FROM prod.PACKAGE P
                    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                    WHERE DATEPART(WEEK,P.VERIFY_DATE) = 11 AND DATEPART(YEAR,P.VERIFY_DATE)  = 2021 AND  P.TYPE_ID = 100026 AND P.VERIFY_DATE is not null
                ) L0
                GROUP BY L0.DEPARTMENT_ID, L0.ITEM_ID
                ) N1 ON (N1.DEPARTMENT_ID = N.DEPARTMENT_ID AND N1.ITEM_ID = N.ITEM_ID) or (N1.DEPARTMENT_ID = X.DEPARTMENT_ID and N1.ITEM_ID = X.ITEM_ID)
				LEFT JOIN
				 (SELECT DEPARTMENT_ID,ITEM_ID,SUM(QUANTITY) XUAT1
                FROM (
                    SELECT P.SOURCE_ID  DEPARTMENT_ID, MIP.ITEM_ID, MIP.QUANTITY
                    FROM prod.PACKAGE P
                    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                    LEFT JOIN prod.MATERIALS_IN_PACKAGE MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
                    WHERE DATEPART(WEEK,P.VERIFY_DATE) = 11 AND DATEPART(YEAR,P.VERIFY_DATE)  = 2021 AND P.TYPE_ID = 100026
                ) L0
                GROUP BY L0.DEPARTMENT_ID, L0.ITEM_ID
                ) X1 ON (X1.DEPARTMENT_ID = X.DEPARTMENT_ID and X1.ITEM_ID = X.ITEM_ID) or (X1.DEPARTMENT_ID = N.DEPARTMENT_ID and X1.ITEM_ID = N.ITEM_ID)

            ) XN 
			left join base.DEPARTMENT D ON D.ID  = XN.DEPARTMENT_ID
          
            FULL OUTER JOIN (
                select ITEM_ID,DEPARTMENT_ID,SUM(QUANTITY) QUANTITY
                from prod.OPENING_STOCK OS
                where OS.createdAt >='20210301' and OS.nguonPhoi = N'Tại tổ'
				GROUP BY DEPARTMENT_ID,ITEM_ID
            ) OS ON OS.ITEM_ID = XN.ITEM_ID AND OS.DEPARTMENT_ID = XN.DEPARTMENT_ID
) as ad on ad.ITEM_ID = i.ID
left join (
	select distinct * from (
  select
					distinct
                     I.ID itemId,
                     I.CODE itemCode,
                     I.NAME itemName,
                     I.LENGTH itemLength,
                     I.WIDTH itemWidth,
                     I.HEIGHT itemHeight,
                   
					 M.NAME root,
                    po.stepId,
                     SUM(ROUND(PO.keHoach - PO.soLuongUuTien + PO.hanMucTon + PO.loiCongDon -(CASE
                         WHEN SL.quantity IS NULL THEN 0
                         ELSE ROUND(SL.quantity,6)
                     END),6)) conThucHien
                     from prod.PO PO
                     left join base.ITEM I ON I.ID = PO.itemId
                     left join base.DEPARTMENT D ON D.ID  = PO.stepId
                     left join base.MARKET M ON M.CODE = PO.root
                     left join base.ITEM P ON P.ID = M.PRODUCT_ID
                     LEFT JOIN (
                         select distinct P.PO,SUM(IIP.QUANTITY) quantity
                         from prod.PACKAGE P
                         left join prod.PACKAGE_TYPE PT ON PT.ID = P.TYPE_ID
                         left join prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                         WHERE 
                         (PT.TYPE_ID <> 100000 OR PT.TYPE_ID IS NULL)
                         AND (PT.TYPE_ID <> 400000 OR PT.TYPE_ID IS NULL) 
                         GROUP BY P.PO
                     ) SL ON SL.PO = PO.code
                     LEFT JOIN (
                         select distinct P.PO,SUM(IIP.QUANTITY) quantity
                         from prod.PACKAGE P
                         left join prod.PACKAGE_TYPE PT ON PT.ID = P.TYPE_ID
                         left join prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                         WHERE PT.TYPE_ID <> 100000
                         AND PT.TYPE_ID <> 400000
                         AND CAST(P.CREATE_DATE  AS DATE) = CAST(GETDATE() AS DATE) 
                         GROUP BY P.PO
                     ) SLN ON SLN.PO = PO.code
                      LEFT JOIN (
                             select distinct P.PO,SUM(IIP.QUANTITY) error
                             from prod.PACKAGE P
                             left join prod.PACKAGE_TYPE PT ON PT.ID = P.TYPE_ID
                             left join prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                             WHERE (PT.TYPE_ID = 100000 OR PT.TYPE_ID = 400000) 
                             GROUP BY P.PO
                         ) ERR ON ERR.PO = PO.code
             where stepId in(select ID from temp) and approvedAt is not null and endPO = 0 and deletedAt is null  and DATEPART(WEEK,PO.createdAt) = @week and DATEPART(YEAR,PO.createdAt) = @year
             GROUP BY     
             I.ID,
             I.CODE ,
             I.NAME ,
             I.LENGTH ,
             I.WIDTH ,
             I.HEIGHT ,
             PO.market,
			 M.NAME,
			 Po.stepId 
 ) as x
) as khth on khth.itemId = i.ID
inner join prod.BOM as b on b.MATERIALS_ID = pgi.ITEM_ID
inner join base.item ib on ib.id = b.ITEM_ID
where DATEPART(WEEK,pg.CREATE_DATE) = @week and DATEPART(YEAR,pg.CREATE_DATE) = @year and ad.DEPARTMENT_ID in(select ID from temp)
) as a

pivot (
	sum(a.qty) for a.thu in ([thu2],[thu3],[thu4],[thu5],[thu6],[thu7],[cn])
) as b
END






GO
/****** Object:  StoredProcedure [dbo].[Proc_createData]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC Proc_createData



CREATE   PROC [dbo].[Proc_createData]
AS
BEGIN
/*
SELECT CONCAT('TRUNCATE TABLE [',S.[name],'].[',T.[name],']')
FROM sys.tables T
LEFT JOIN sys.schemas S ON S.schema_id = T.schema_id
*/
TRUNCATE TABLE [base].[ITEM]
TRUNCATE TABLE [base].[ITEM_TYPE]
TRUNCATE TABLE [dbo].[ITEM_IN_PLAN]
TRUNCATE TABLE [base].[UNIT]
TRUNCATE TABLE [base].[MARKET]
TRUNCATE TABLE [base].[PACKAGE_TYPE]
TRUNCATE TABLE [base].[PALLET_TYPE]
TRUNCATE TABLE [dbo].[REQUIRE]
TRUNCATE TABLE [dbo].[ROUTING]
TRUNCATE TABLE [dbo].[WORK_RESOURCES]
TRUNCATE TABLE [dbo].[WORK_CENTER]
TRUNCATE TABLE [dbo].[PACKAGE]
TRUNCATE TABLE [dbo].[KILN_BATCH]
TRUNCATE TABLE [dbo].[RANGE]
TRUNCATE TABLE [dbo].[ORDER]
TRUNCATE TABLE [dbo].[FACTORY]
TRUNCATE TABLE [dbo].[STEP]
TRUNCATE TABLE [dbo].[KILN]
TRUNCATE TABLE [dbo].[UNIT]
TRUNCATE TABLE [dbo].[BOM_SUPPLIES]
TRUNCATE TABLE [dbo].[TABLE]
TRUNCATE TABLE [dbo].[PERMISSION]
TRUNCATE TABLE [dbo].[ACCOUNT]
TRUNCATE TABLE [dbo].[ROLE]
TRUNCATE TABLE [dbo].[ROLE_TYPE]
TRUNCATE TABLE [dbo].[ROLE_VALUE]
TRUNCATE TABLE [dbo].[ITEM_IN_PALLET]
TRUNCATE TABLE [dbo].[PALLET_SUPPLIES]
TRUNCATE TABLE [dbo].[ITEM_IN_PACKAGE]
TRUNCATE TABLE [dbo].[MATERIALS_IN_PACKAGE]
TRUNCATE TABLE [dbo].[DEPARTMENT]
TRUNCATE TABLE [dbo].[XUONG]
TRUNCATE TABLE [dbo].[STEP_OF_PALLET]
TRUNCATE TABLE [dbo].[PLAN]
TRUNCATE TABLE [dbo].[PLAN_ID]
TRUNCATE TABLE [dbo].[STEP_ORDER]
TRUNCATE TABLE [dbo].[BOM]
TRUNCATE TABLE [dbo].[MARKET]
TRUNCATE TABLE [dbo].[GLOBAL_DATE]
TRUNCATE TABLE [dbo].[PACKAGE_TYPE]
TRUNCATE TABLE [dbo].[PALLET_STATE]
TRUNCATE TABLE [base].[ROLE]
TRUNCATE TABLE [base].[ROLE_TYPE]
TRUNCATE TABLE [base].[ACCOUNT]
TRUNCATE TABLE [base].[ROLE_VALUE]
TRUNCATE TABLE [dbo].[ITEM]
TRUNCATE TABLE [dbo].[PALLET_TYPE]
TRUNCATE TABLE [dbo].[PALLET]
TRUNCATE TABLE [base].[FACTORY]
TRUNCATE TABLE [base].[XUONG]
TRUNCATE TABLE [base].[DEPARTMENT]
TRUNCATE TABLE [base].[STEP]

DECLARE @DATE DATETIME = '2019-01-01'
DECLARE @TO INT = 1800 --5 năm

WHILE @TO > 0
BEGIN
SET @TO = @TO - 1
SET @DATE = @DATE + 1

INSERT INTO dbo.[GLOBAL_DATE]([GUID],CODE,[YEAR],[MONTH],[WEEK],[DAY],[YEAR_MONTH],[YEAR_WEEK])
SELECT NEWID() , 
CASE 
	WHEN MONTH(@DATE) < 10 AND DAY(@DATE) < 10 THEN CONCAT(YEAR(@DATE),'0',MONTH(@DATE),'0', DAY(@DATE))
	WHEN MONTH(@DATE) < 10 AND DAY(@DATE) > 10 THEN CONCAT(YEAR(@DATE),'0',MONTH(@DATE), DAY(@DATE))
	WHEN MONTH(@DATE) < 10 AND DAY(@DATE) = 10 THEN CONCAT(YEAR(@DATE),'0',MONTH(@DATE), DAY(@DATE))
	WHEN MONTH(@DATE) > 10 AND DAY(@DATE) < 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE),'0', DAY(@DATE))
	WHEN MONTH(@DATE) > 10 AND DAY(@DATE) > 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE), DAY(@DATE))
	WHEN MONTH(@DATE) > 10 AND DAY(@DATE) = 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE), DAY(@DATE))
	WHEN MONTH(@DATE) = 10 AND DAY(@DATE) < 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE),'0', DAY(@DATE))
	WHEN MONTH(@DATE) = 10 AND DAY(@DATE) > 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE), DAY(@DATE))
	WHEN MONTH(@DATE) = 10 AND DAY(@DATE) = 10 THEN CONCAT(YEAR(@DATE),MONTH(@DATE), DAY(@DATE))
END AS CODE,
YEAR(@DATE),
MONTH(@DATE),
DATEPART(WK,@DATE),
DAY(@DATE),
CASE 
	WHEN MONTH(@DATE) < 10 THEN CONCAT(YEAR(@DATE),'0',MONTH(@DATE))
	ELSE CONCAT(YEAR(@DATE),MONTH(@DATE))
END AS YEAR_MONTH,
CASE 
	WHEN DATEPART(WK,@DATE) < 10 THEN CONCAT(YEAR(@DATE),'0',DATEPART(WK,@DATE))
	ELSE CONCAT(YEAR(@DATE),DATEPART(WK,@DATE))
END AS YEAR_WEEK

END


INSERT INTO dbo.[PACKAGE_TYPE]([GUID],[CODE],[NAME],TYPE_ID)
VALUES(NEWID(),'ND',N'Nứt đầu',100000),
(NEWID(),'BC',N'Bẩn cạnh',100000),
(NEWID(),'HONG',N'Phôi hỏng',100000),
(NEWID(),'CLG',N'Chất lượng gỗ',100000),
(NEWID(),'LGC',N'Lỗi gia công',100000),
(NEWID(),'LMG',N'Lỗi mối ghép',100000),
(NEWID(),'LDVC',N'Lỗi do vận chuyển',100000),
(NEWID(),'D',N'Đạt',100001),
(NEWID(),'DB4M',N'Đã bào 4 mặt',100001),
(NEWID(),'DC2D',N'Đã cắt 2 đầu',100001)

--TRUNCATE TABLE dbo.[FACTORY]
INSERT INTO dbo.[FACTORY]
VALUES 	(NEWID(),'TH',N'Thuận Hưng'), --0
		(NEWID(),'YS',N'Yên Sơn'), --1
		(NEWID(),'WL',N'Woodsland'), --2
		(NEWID(),'NH',N'Nam Hồng'), --3
		(NEWID(),'VH',N'Việt Hà')--4

INSERT INTO dbo.[XUONG]
VALUES  (NEWID(),100000,'TH',N'Thuận Hưng Outdoor '), --0
		(NEWID(),100001,'YS',N'Yên Sơn'), --1
		(NEWID(),100002,'WL',N'Woodsland'), --2
		(NEWID(),100003,'NH',N'Nam Hồng'), --3
		(NEWID(),100004,'VH',N'Việt Hà'),--4
		(NEWID(),100000,'TH-I',N'Thuận Hưng Indoor') --5


--TRUNCATE TABLE dbo.[DEPARTMENT]
INSERT INTO dbo.[DEPARTMENT]
VALUES (NEWID(),100000,'O-NVL',N'Nguyên vật liệu'), --0
(NEWID(),100000,'O-SC',N'Sơ chế'), --1
(NEWID(),100000,'O-TC',N'Tinh chế'), --2
(NEWID(),100000,'O-HTBM',N'Hoàn thiện bề mặt'), --3
(NEWID(),100000,'O-LR',N'Lắp ráp'), --4
(NEWID(),100000,'O-DG',N'Đóng gói'), --5
(NEWID(),100000,'O-QC',N'Quản lý chất lượng'), --6
(NEWID(),100000,'O-VGT',N'Ván ghép thanh'), --7
(NEWID(),100000,'KH',N'Kế hoạch'), --8
(NEWID(),100005,'I-NVL',N'Nguyên vật liệu'), --9
(NEWID(),100005,'I-SC',N'Sơ chế'), --10
(NEWID(),100005,'I-TC',N'Tinh chế'), --11
(NEWID(),100005,'I-HTBM',N'Hoàn thiện bề mặt'), --12
(NEWID(),100005,'I-LR',N'Lắp ráp'), --13
(NEWID(),100005,'I-DG',N'Đóng gói'), --14
(NEWID(),100005,'I-QC',N'Quản lý chất lượng'), --15
(NEWID(),100005,'I-VGT',N'Ván ghép thanh'), --16
(NEWID(),100005,'I-KH',N'Kế hoạch') --17

--TRUNCATE TABLE dbo.[STEP]
INSERT INTO dbo.[STEP]
VALUES (NEWID(),100000,'XCS',N'Xếp sấy'),
(NEWID(),100000,'CS',N'Chờ sấy'),
(NEWID(),100000,'S',N'Sấy'),
(NEWID(),100000,'RL',N'Ra lò'),
(NEWID(),100000,'LP',N'Lựa phôi'),
(NEWID(),100000,'C',N'Cắt'),
(NEWID(),100000,'KLP',N'Kho lựa phôi'),
(NEWID(),100001,'B4M',N'Bào 4 mặt'),
(NEWID(),100002,'C2D',N'Cắt 2 đầu'),
(NEWID(),100002,'U',N'Uốn'),
(NEWID(),100002,'MD',N'Mộng dương'),
(NEWID(),100002,'MA',N'Mộng âm'),
(NEWID(),100002,'K',N'Khoan'),
(NEWID(),100002,'GC',N'Ghép chân'),
(NEWID(),100002,'CNC',N'Cắt CNC'),
(NEWID(),100003,'B',N'Bả'),
(NEWID(),100003,'CN',N'Chà nhám'),
(NEWID(),100003,'SH',N'Sửa hàng'),
(NEWID(),100004,'LRM',N'Lắp ráp mộc'),
(NEWID(),100004,'ND1',N'Nhúng dầu nước 1'),
(NEWID(),100004,'CC',N'Chà chổi'),
(NEWID(),100004,'ND2',N'Nhúng dầu nước 2'),
(NEWID(),100004,'XN',N'Xóa nhám'),
(NEWID(),100004,'LRPK',N'Lắp ráp phụ kiện'),
(NEWID(),100005,'DG',N'Đóng gói'),
(NEWID(),100006,'QC',N'QC'),
(NEWID(),100005,'KTP',N'Kho thành phẩm'), --26
(NEWID(),100009,'LPIN',N'Lựa phôi indoor'), --27
(NEWID(),100000, 'B2M',N'Bào 2 mặt'),
(NEWID(),100001, 'MTUBY',N'Máy tuby'),
(NEWID(),100007, 'GN',N'Ghép ngang'),
(NEWID(),100007, 'CR',N'Cưa rong'),
(NEWID(),100007, 'MX63',N'Máy xẻ chân 63'),
(NEWID(),100007, 'MC63',N'Máy cắt chân 63'),
(NEWID(),100007, 'CV',N'Cưa vanh'),
(NEWID(),100002, 'C1D',N'Cắt 1 đầu'),
(NEWID(),100002, 'BD',N'Bo đầu'),
(NEWID(),100002, 'MGH',N'Máy chép hình'),
(NEWID(),100002, 'BROTO',N'Bo Roto'),
(NEWID(),100002, 'PGF',N'Phay ghép Finger'),
(NEWID(),100002, 'MV',N'Máy vanh'),
(NEWID(),100002, 'NDC',N'Nối dọc chân'),
(NEWID(),100003, 'ML',N'Máy lạng'),
(NEWID(),100003, 'MCTC',N'Máy chà thanh cong'),
(NEWID(),100003, 'DCMP',N'Dán chân mặt Pallet'),
(NEWID(),100003, 'DGPK',N'Đóng gói phụ kiện'),
(NEWID(),100008, 'KH',N'Kế hoạch'),
(NEWID(),100009, 'IKLP',N'Kho lựa phôi Indoor'), --47 --Đây là pallet giao lên cắt thống kê theo thanh
(NEWID(),100010, 'IB2M',N'Bào 2 mặt'),
(NEWID(),100010, 'ICATKT',N'Cắt bỏ khuyết tật'), --49 -- Tạo pallet mới với khối lượng x và giao lên ghép dọc
(NEWID(),100010, 'IGD',N'Ghép dọc'), --50 -- Tạo pallet thống kê theo thanh
(NEWID(),100010, 'TGN',N'Ghép ngang'), -- 51 -- Tạo pallet thống kê theo tấm
(NEWID(),100010, 'IGC',N'Ghép chập'), -- 52 không tạo pallet mà chỉ chuyển tẩm đó sang công đoạn ghép chập
(NEWID(),100010, 'IBCT',N'Bào chà tinh'),
(NEWID(),100010, 'IB4M',N'Bào 4 mặt'),
(NEWID(),100010, 'IU',N'Uốn gỗ'),
(NEWID(),100011, 'IC2D',N'Cắt 2 đầu'),
(NEWID(),100011, 'IMA',N'Mộng âm'),
(NEWID(),100011, 'IMD',N'Mộng dương'),
(NEWID(),100011, 'IP',N'Phay'),
(NEWID(),100011, 'IK',N'Khoan'),
(NEWID(),100011, 'ICNC',N'CNC'),
(NEWID(),100012, 'IB',N'Bả'),
(NEWID(),100012, 'ICN',N'Chà nhám'),
(NEWID(),100012, 'ISHM',N'Sửa hàng mộc'),
(NEWID(),100012, 'IWax1',N'Wax1'),
(NEWID(),100012, 'ICC',N'Chà chổi'),
(NEWID(),100012, 'IWax2',N'Wax2'),
(NEWID(),100012, 'ICC2',N'Chà chổi 2'),
(NEWID(),100012, 'IWax3',N'Wax3'),
(NEWID(),100012, 'ICC3',N'Chà chổi 3'),
(NEWID(),100012, 'ISH',N'Sửa hàng'),
(NEWID(),100012, 'IDG',N'Đóng gói'), --72
(NEWID(),100013, 'ILRM',N'Lắp ráp mộc'), --73
(NEWID(),100013, 'ILRPK',N'Lắp ráp phụ kiện'), --74
(NEWID(), 100000,'VGT',N'Ván ghép thanh'), --75
(NEWID(), 100000,'SL',N'Sấy lại') --76




INSERT INTO dbo.[KILN]
VALUES(NEWID(),'L1',N'Lò 1'),
(NEWID(),'L2',N'Lò 2'),
(NEWID(),'L3',N'Lò 3'),
(NEWID(),'L4',N'Lò 4'),
(NEWID(),'L5',N'Lò 5'),
(NEWID(),'L6',N'Lò 6'),
(NEWID(),'L7',N'Lò 7'),
(NEWID(),'L8',N'Lò 8')

--TRUNCATE TABLE dbo.[ROLE]
INSERT INTO dbo.[ROLE]([GUID],[CODE],[NAME])
VALUES (NEWID(),'admin',N'Admin'), --0
(NEWID(),'xepsay',N'Xếp sấy'), --1
(NEWID(),'chosay',N'Chờ sấy'), --2
(NEWID(),'say',N'Sấy'), --3
(NEWID(),'ralo',N'Ra lò'), --4
(NEWID(),'luaphoi',N'Lựa phôi'), --5
(NEWID(),'cat',N'Cắt'), --6
(NEWID(),'kholuaphoi',N'Kho lựa phôi'), --7
(NEWID(),'b4m',N'Bào 4 mặt'), --8
(NEWID(),'c2d',N'Cắt 2 đầu'), --9
(NEWID(),'u',N'Uốn'), --10
(NEWID(),'md',N'Mộng dương'), --11
(NEWID(),'ma',N'Mộng âm'), --12
(NEWID(),'k',N'Khoan'), --13
(NEWID(),'gc',N'Ghép chân'), --14
(NEWID(),'cnc',N'Cắt CNC'), --15
(NEWID(),'b',N'Bả'), --16
(NEWID(),'cn',N'Chà nhám'), --17
(NEWID(),'sh',N'Sửa hàng'), --18
(NEWID(),'lrm',N'Lắp ráp mộc'), --19
(NEWID(),'nd1',N'Nhúng dầu 1'), --20
(NEWID(),'cc',N'Chà chổi'), --21
(NEWID(),'nd2',N'Nhúng dầu 2'), --22
(NEWID(),'xn',N'Xóa nhám'), --23
(NEWID(),'lrpk',N'Lắp ráp phụ kiện'), --24
(NEWID(),'dg',N'Đóng gói'), --25
(NEWID(),'qc',N'Quản lý chất lượng'), --26
(NEWID(),'ktp',N'Kho thành phẩm'), --27
(NEWID(),'kh',N'Kế hoạch'), -- 28
(NEWID(),'B2M',N'Bào 2 mặt'), --29
(NEWID(), 'MTUBY',N'Máy tuby'), --30
(NEWID(), 'GN',N'Ghép ngang'), --31
(NEWID(), 'CR',N'Cưa rong'), --32
(NEWID(), 'MX63',N'Máy xẻ chân 63'), --33
(NEWID(), 'MC63',N'Máy cắt chân 63'), --34
(NEWID(), 'CV',N'Cưa vanh'), --35
(NEWID(), 'C1D',N'Cắt 1 đầu'), --36
(NEWID(), 'BD',N'Bo đầu'), --37
(NEWID(), 'MGH',N'Máy chép hình'), --38
(NEWID(), 'BROTO',N'Bo Roto'), --39
(NEWID(), 'PGF',N'Phay ghép Finger'), --40
(NEWID(), 'MV',N'Máy vanh'), --41
(NEWID(), 'NDC',N'Nối dọc chân'), --42
(NEWID(), 'ML',N'Máy lạng'), --43
(NEWID(), 'MCTC',N'Máy chà thanh cong'), --44
(NEWID(), 'DCMP',N'Dán chân mặt Pallet'), --45
(NEWID(), 'DGPK',N'Đóng gói phụ kiện'), --46
(NEWID(), 'qcls', N'Quản lý chất lượng của lò sấy'), --47
(NEWID(), 'ilp',N'Lựa phôi Indoor'), --48
(NEWID(), 'iklp',N'Kho lựa phôi'), --49
(NEWID(), 'ib2m',N'Bào 2 mặt'), --50
(NEWID(), 'icatkt',N'Cắt bỏ khuyết tật'),--51
(NEWID(), 'igd',N'Ghép dọc'), --52
(NEWID(), 'ign',N'Ghép ngang'), --53
(NEWID(), 'igc',N'Ghép chập'),--54
(NEWID(), 'ibct',N'Bào chà tinh'),--55
(NEWID(), 'ib4m',N'Bào 4 mặt'),--56
(NEWID(), 'iug',N'Uốn gỗ'), --57
(NEWID(), 'ic2d',N'Cắt 2 đầu'),
(NEWID(), 'ima',N'Mộng âm'),
(NEWID(), 'imd',N'Mộng dương'),
(NEWID(), 'ip',N'Phay'),
(NEWID(), 'ik',N'Khoan'),
(NEWID(), 'icnc',N'CNC'),
(NEWID(), 'iba',N'Bả'),
(NEWID(), 'icn',N'Chà nhám'),
(NEWID(), 'ishm',N'Sửa hàng mộc'),
(NEWID(), 'iw1',N'Wax 1'),
(NEWID(), 'ic1',N'Chà chổi 1'),
(NEWID(), 'iw2',N'Wax2'),
(NEWID(), 'ic2',N'Chà chổi 2'),
(NEWID(), 'iw3',N'Wax3'),
(NEWID(), 'ic3',N'Chà chổi 3'),
(NEWID(), 'ish',N'Sửa hàng'),
(NEWID(), 'idg',N'Đóng gói'),
(NEWID(), 'ilrm',N'Lắp ráp mộc'),
(NEWID(), 'ilrpk',N'Lắp ráp phụ kiện'),--76
(NEWID(), 'dev',N'Đi-vơ-lốp') --77



INSERT INTO dbo.[ROLE_TYPE]([GUID],[CODE],[NAME])
VALUES(NEWID(),'T',N'Table'), --0
(NEWID(),'S',N'Source'), --1
(NEWID(),'D',N'Destiantion') --2

--TRUNCATE TABLE dbo.[RANGE]
INSERT INTO dbo.[RANGE]([GUID],[TYPE],HEIGHT,CODE,TIME_OUT_TARGET,STEP_NEXT_ID)
VALUES (NEWID(),N'Outdoor',N'14-16',N'Outdoor14-16','15',100004),
(NEWID(),N'Indoor',N'19-21',N'Indoor19-21','23',100027),
(NEWID(),N'Outdoor',N'19-21',N'Outdoor19-21','20',100004),
(NEWID(),N'Indoor',N'24-27',N'Indoor24-27','25',100027),
(NEWID(),N'Outdoor',N'21-24',N'Outdoor21-24','22',100004),
(NEWID(),N'Outdoor',N'30-31',N'Outdoor30-31','33',100004),
(NEWID(),N'Indoor',N'30-31',N'Indoor30-31','30',100027),
(NEWID(),N'Outdoor',N'Ván 24',N'OutdoorVán 24','28',100004),
(NEWID(),N'Indoor',N'Ván 24',N'IndoorVán 24','24',100027),
(NEWID(),N'Indoor',N'Ván 31',N'IndoorVán 31','25',100027),
(NEWID(),N'Outdoor',N'Ván 31,38',N'OutdoorVán 31,38','33',100004),
(NEWID(),N'Indoor',N'Ván 31,38',N'IndoorVán 31,38','40',100027),
(NEWID(),N'Sấy lại Outdoor',N'19-38',N'Sấy lại19-38','10',100004),
(NEWID(),N'Sấy lại Indoor',N'19-38',N'Sấy lại19-38','10',100027)





--TRUNCATE TABLE dbo.[ROLE_VALUE]
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100001,100001,100000),
		(NEWID(),100001,100002,100001)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100002,100001,100001),
		(NEWID(),100002,100002,100002)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100003,100001,100002),
		(NEWID(),100003,100002,100003)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100004,100001,100003),
		(NEWID(),100004,100002,100004)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100005,100001,100004),
		(NEWID(),100005,100002,100005),
		(NEWID(),100005,100002,100006),
		(NEWID(),100005,100002,100027),
		(NEWID(),100005,100002,100075),
		(NEWID(),100005,100002,100076)

INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES (NEWID(),100006,100001,100005),
	(NEWID(),100006,100002,100004),
	(NEWID(),100006,100002,100075),
	(NEWID(),100006,100002,100048)

INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100007,100001,100006),
	(NEWID(),100007,100002,100007)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100008,100001,100007),
	(NEWID(),100008,100002,100008),
	(NEWID(),100008,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100009,100001,100008),
	(NEWID(),100009,100002,100009),
	(NEWID(),100009,100002,100010),
	(NEWID(),100009,100002,100011),
	(NEWID(),100009,100002,100012),
	(NEWID(),100009,100002,100013),
	(NEWID(),100009,100002,100014),
	(NEWID(),100009,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100010,100001,100009),
	(NEWID(),100010,100002,100010),
	(NEWID(),100010,100002,100011),
	(NEWID(),100010,100002,100012),
	(NEWID(),100010,100002,100013),
	(NEWID(),100010,100002,100014),
	(NEWID(),100010,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100011,100001,100010),
	(NEWID(),100011,100002,100009),
	(NEWID(),100011,100002,100011),
	(NEWID(),100011,100002,100012),
	(NEWID(),100011,100002,100013),
	(NEWID(),100011,100002,100014),
	(NEWID(),100011,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100011,100002,100015),
(NEWID(),100011,100002,100016),
(NEWID(),100011,100002,100017)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100012,100001,100011),
	(NEWID(),100012,100002,100009),
	(NEWID(),100012,100002,100010),
	(NEWID(),100012,100002,100012),
	(NEWID(),100012,100002,100013),
	(NEWID(),100012,100002,100014),
	(NEWID(),100012,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100012,100002,100015),
(NEWID(),100012,100002,100016),
(NEWID(),100012,100002,100017)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100013,100001,100012),
	(NEWID(),100013,100002,100009),
	(NEWID(),100013,100002,100010),
	(NEWID(),100013,100002,100011),
	(NEWID(),100013,100002,100013),
	(NEWID(),100013,100002,100014),
	(NEWID(),100013,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100013,100002,100015),
(NEWID(),100013,100002,100016),
(NEWID(),100013,100002,100017)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100014,100001,100013),
	(NEWID(),100014,100002,100009),
	(NEWID(),100014,100002,100010),
	(NEWID(),100014,100002,100011),
	(NEWID(),100014,100002,100012),
	(NEWID(),100014,100002,100014),
	(NEWID(),100014,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100014,100002,100015),
(NEWID(),100014,100002,100016),
(NEWID(),100014,100002,100017)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100015,100001,100014),
	(NEWID(),100015,100002,100009),
	(NEWID(),100015,100002,100010),
	(NEWID(),100015,100002,100011),
	(NEWID(),100015,100002,100012),
	(NEWID(),100015,100002,100013),
	(NEWID(),100015,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100015,100002,100015),
(NEWID(),100015,100002,100016),
(NEWID(),100015,100002,100017)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100016,100001,100015),
	(NEWID(),100016,100002,100016),
	(NEWID(),100016,100002,100016),
	(NEWID(),100016,100002,100017),
	(NEWID(),100016,100002,100018),
	(NEWID(),100016,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100017,100001,100016),
	(NEWID(),100017,100002,100016),
	(NEWID(),100017,100002,100017),
	(NEWID(),100017,100002,100018),
	(NEWID(),100017,100002,100025)

INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100018,100001,100017),
	(NEWID(),100018,100002,100016),
	(NEWID(),100018,100002,100017),
	(NEWID(),100018,100002,100018),
	(NEWID(),100018,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100019,100001,100018),
	(NEWID(),100019,100002,100018),
	(NEWID(),100019,100002,100019),
	(NEWID(),100019,100002,100020),
	(NEWID(),100019,100002,100021),
	(NEWID(),100019,100002,100022),
	(NEWID(),100019,100002,100023),
	(NEWID(),100019,100002,100024),
	(NEWID(),100019,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100020,100001,100019),
	(NEWID(),100020,100002,100018),
	(NEWID(),100020,100002,100019),
	(NEWID(),100020,100002,100020),
	(NEWID(),100020,100002,100021),
	(NEWID(),100020,100002,100022),
	(NEWID(),100020,100002,100023),
	(NEWID(),100020,100002,100024),
	(NEWID(),100020,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100021,100001,100020),
	(NEWID(),100021,100002,100018),
	(NEWID(),100021,100002,100019),
	(NEWID(),100021,100002,100020),
	(NEWID(),100021,100002,100021),
	(NEWID(),100021,100002,100022),
	(NEWID(),100021,100002,100023),
	(NEWID(),100021,100002,100024),
	(NEWID(),100021,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100022,100001,100021),
	(NEWID(),100022,100002,100018),
	(NEWID(),100022,100002,100019),
	(NEWID(),100022,100002,100020),
	(NEWID(),100022,100002,100021),
	(NEWID(),100022,100002,100022),
	(NEWID(),100022,100002,100023),
	(NEWID(),100022,100002,100024),
	(NEWID(),100022,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100023,100001,100022),
	(NEWID(),100023,100002,100018),
	(NEWID(),100023,100002,100019),
	(NEWID(),100023,100002,100020),
	(NEWID(),100023,100002,100021),
	(NEWID(),100023,100002,100022),
	(NEWID(),100023,100002,100023),
	(NEWID(),100023,100002,100024),
	(NEWID(),100023,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100024,100001,100023),
	(NEWID(),100024,100002,100019),
	(NEWID(),100024,100002,100020),
	(NEWID(),100024,100002,100021),
	(NEWID(),100024,100002,100022),
	(NEWID(),100024,100002,100023),
	(NEWID(),100024,100002,100024),
	(NEWID(),100024,100002,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100025,100001,100024),
	(NEWID(),100025,100002,100026)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100026,100001,100025),
	(NEWID(),100026,100002,100005)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100027,100001,100026),
	(NEWID(),100027,100002,100027)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100028,100001,100046),
		(NEWID(),100028,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100029,100001,100028),
(NEWID(),100029,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100030,100001,100029),
(NEWID(),100030,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100031,100001,100030),
(NEWID(),100031,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100032,100001,100031),
(NEWID(),100032,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100033,100001,100032),
(NEWID(),100033,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100034,100001,100033),
(NEWID(),100034,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100035,100001,100034),
(NEWID(),100035,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100036,100001,100035),
(NEWID(),100036,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100037,100001,100036),
(NEWID(),100037,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100038,100001,100037),
(NEWID(),100038,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100039,100001,100038),
(NEWID(),100039,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100040,100001,100039),
(NEWID(),100040,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100041,100001,100040),
(NEWID(),100041,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100042,100001,100041),
(NEWID(),100042,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100043,100001,100042),
(NEWID(),100043,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100044,100001,100043),
(NEWID(),100044,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100045,100001,100044),
(NEWID(),100045,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100046,100001,100045),
(NEWID(),100046,100002,100000)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100047,100001,100025)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100048,100001,100027)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100048,100002,100047)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100049,100001,100047)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100050,100001,100048)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100051,100001,100049)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100051,100002,100050)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100052,100001,100050)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100052,100002,100051)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100053,100001,100051)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100053,100002,100053)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100054,100001,100052)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100055,100001,100053)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100056,100001,100054)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100057,100001,100055)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100058,100001,100056)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100059,100001,100057)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100060,100001,100058)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100061,100001,100059)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100062,100001,100060)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100063,100001,100061)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100064,100001,100062)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100065,100001,100063)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100066,100001,100064)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100067,100001,100065)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100068,100001,100066)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100069,100001,100067)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100070,100001,100068)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100071,100001,100069)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100072,100001,100070)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100073,100001,100071)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100074,100001,100072)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100075,100001,100073)
INSERT INTO dbo.[ROLE_VALUE]([GUID],ROLE_ID,ROLE_TYPE,[VALUE])
VALUES(NEWID(),100076,100001,100074)




--TRUNCATE TABLE dbo.[ACCOUNT]
INSERT INTO dbo.[ACCOUNT]([GUID],ACCOUNT,[PASSWORD],[NAME],ROLE_ID)
VALUES(NEWID(),'admin','$2b$10$8JYCUrjehP89jJuy/TpnT.HBiydFE//qG6GSSNdywbxCj9REwgq6O','Adminstration',100000),
(NEWID(),'xepsay','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100001),
(NEWID(),'chosay','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100002),
(NEWID(),'losay','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100003),
(NEWID(),'ralo','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100004),
(NEWID(),'luaphoi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100005),
(NEWID(),'cat','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100006),
(NEWID(),'kholuaphoi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100007),
(NEWID(),'bao4mat','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100008),
(NEWID(),'cat2dau','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100009),
(NEWID(),'uon','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100010),
(NEWID(),'mongduong','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100011),
(NEWID(),'mongam','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100012),
(NEWID(),'khoan','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100013),
(NEWID(),'ghepchan','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100014),
(NEWID(),'cnc','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100015),
(NEWID(),'ba','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100016),
(NEWID(),'chanham','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100017),
(NEWID(),'suahang','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100018),
(NEWID(),'laprapmoc','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100019),
(NEWID(),'nhungdau1','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100020),
(NEWID(),'chachoi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100021),
(NEWID(),'nhungdau2','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100022),
(NEWID(),'xoanham','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100023),
(NEWID(),'laprapphukien','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100024),
(NEWID(),'donggoi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100025),
(NEWID(),'qc','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100026),
(NEWID(),'khothanhpham','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100027),
(NEWID(),'kh','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100028),
(NEWID(),'bao2mat','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100029),
(NEWID(),'mtuby','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100030),
(NEWID(),'ghepngang','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100031),
(NEWID(),'cuarong','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100032),
(NEWID(),'mayxe63','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100033),
(NEWID(),'maycat63','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100034),
(NEWID(),'cuavanh','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100035),
(NEWID(),'cat1dau','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100036),
(NEWID(),'bodau','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100037),
(NEWID(),'mayghephinh','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100038),
(NEWID(),'boroto','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100039),
(NEWID(),'phayghep','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100040),
(NEWID(),'mayvanh','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100041),
(NEWID(),'noidocchan','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100042),
(NEWID(),'maylang','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100043),
(NEWID(),'maycha','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100044),
(NEWID(),'danchan','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100045),
(NEWID(),'donggoiphukien','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100046),
(NEWID(),'qcls','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm',N'QC lò sấy',100047),
(NEWID(),'luaphoii','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100048),
(NEWID(),'kholuaphoii','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100049),
(NEWID(),'bao2mati','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100050),
(NEWID(),'catkti','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100051),
(NEWID(),'ghepdoci','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100052),
(NEWID(),'ghepngangi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100053),
(NEWID(),'ghepchapi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100054),
(NEWID(),'baochatinhi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100055),
(NEWID(),'bao4mati','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100056),
(NEWID(),'uongoi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100057),
(NEWID(),'cat2daui','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100058),
(NEWID(),'mongami','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100059),
(NEWID(),'mongduongi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100060),
(NEWID(),'phayi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100061),
(NEWID(),'khoani','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100062),
(NEWID(),'cnci','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100063),
(NEWID(),'bai','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100064),
(NEWID(),'chanhami','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100065),
(NEWID(),'suahangmoci','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100066),
(NEWID(),'wax1i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100067),
(NEWID(),'chachoi1i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100068),
(NEWID(),'wax2i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100069),
(NEWID(),'chachoi2i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100070),
(NEWID(),'wax3i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100071),
(NEWID(),'chachoi3i','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100072),
(NEWID(),'suahangi','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100073),
(NEWID(),'donggoii','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100074),
(NEWID(),'laprapmoci','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100075),
(NEWID(),'laprapphukieni','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100076),
(NEWID(),'dev','$2b$10$.s7LIIlFTdrXEyKZLdQspO3qFd0t1QrCMdlMRqnfQosm4akq3IIVm','',100077)


--TRUNCATE TABLE dbo.[PLAN_ID]
INSERT INTO dbo.[PLAN_ID]([GUID],CODE,STEP_ID)
SELECT NEWID(),GD.YEAR_WEEK,S.ID STEP_ID
FROM dbo.[GLOBAL_DATE] GD ,dbo.[STEP] S
WHERE GD.YEAR_WEEK BETWEEN '201920' AND '201940'
GROUP BY GD.YEAR_WEEK,
S.ID
ORDER BY GD.YEAR_WEEK,S.ID



--TRUNCATE TABLE dbo.[PLAN]


INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,ITEM_ID,QUANTITY)
VALUES (NEWID(),'201935','2019','35',100004,109733,1000),
(NEWID(),'201935','2019','35',100004,109734,1000),
(NEWID(),'201935','2019','35',100027,109816,1000),
(NEWID(),'201935','2019','35',100027,109817,1000)
INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,ITEM_ID,QUANTITY)
VALUES (NEWID(),'201935','2019','35',100030,109861,1000),
(NEWID(),'201935','2019','35',100030,109862,1000)

INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,ITEM_ID,QUANTITY)
VALUES (NEWID(),'201936','2019','36',100004,109733,1000),
(NEWID(),'201936','2019','36',100004,109734,1000),
(NEWID(),'201936','2019','36',100027,109816,1000),
(NEWID(),'201936','2019','36',100027,109817,1000)
INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,ITEM_ID,QUANTITY)
VALUES (NEWID(),'201936','2019','36',100030,109861,1000),
(NEWID(),'201936','2019','36',100030,109862,1000)

/*
INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,CREATE_BY,CREATE_DATE)
VALUES (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100000,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100001,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100002,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100003,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100004,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100005,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100006,100000,GETDATE()),
 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100007,100000,GETDATE()),
  (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100008,100000,GETDATE()),
  (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100009,100000,GETDATE()),
    (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100010,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100011,100000,GETDATE()),
	  (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100012,100000,GETDATE()),
	   (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100013,100000,GETDATE()),
	    (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100014,100000,GETDATE()),
		 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100015,100000,GETDATE()),
		  (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100016,100000,GETDATE()),
	   (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100017,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100018,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100019,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100020,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100021,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100022,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100023,100000,GETDATE()),
	 (NEWID(),CONCAT(YEAR(GETDATE()),DATEPART(WK,GETDATE())) ,YEAR(GETDATE()),DATEPART(WK,GETDATE()), 100024,100000,GETDATE())
--TRUNCATE TABLE dbo.[ITEM_IN_PLAN]
 INSERT INTO dbo.[ITEM_IN_PLAN]([GUID],PLAN_ID,[ITEM_ID],[ITEM_CODE],QUANTITY)
 VALUES (NEWID(),100000,109230,'',1000),
 (NEWID(),100000,109231,'',1000),
 (NEWID(),100000,109232,'',1000),
 (NEWID(),100000,109233,'',1000),
 (NEWID(),100001,109230,'',1000),
 (NEWID(),100002,109230,'',1000),
 (NEWID(),100003,109230,'',1000),
 (NEWID(),100004,109732,'',1000),
  (NEWID(),100004,109733,'',1000),
   (NEWID(),100004,109734,'',1000),
    (NEWID(),100004,109735,'',1000),
 (NEWID(),100004,109736,'',1000),
 (NEWID(),100005,109732,'',1000),
 (NEWID(),100006,109732,'',1000),
 (NEWID(),100006,109733,'',1000),
 (NEWID(),100006,109734,'',1000),
 (NEWID(),100006,109735,'',1000),
 (NEWID(),100006,109736,'',1000),
 (NEWID(),100007,109732,'',1000),
 (NEWID(),100008,109732,'',1000),
 (NEWID(),100009,109732,'',1000),
 (NEWID(),100010,109732,'',1000),
 (NEWID(),100011,100000,'',1000),
 (NEWID(),100012,100000,'',1000),
 (NEWID(),100013,100000,'',1000),
 (NEWID(),100014,100000,'',1000),
 (NEWID(),100015,100000,'',1000),
 (NEWID(),100016,100000,'',1000),
 (NEWID(),100017,100000,'',1000),
 (NEWID(),100018,109731,'',1000),
 (NEWID(),100018,109732,'',1000),
 (NEWID(),100018,109733,'',1000),
 (NEWID(),100018,109734,'',1000),
 (NEWID(),100018,109735,'',1000),
 (NEWID(),100019,109218,'',1000),
 (NEWID(),100020,109218,'',1000),
 (NEWID(),100021,109218,'',1000),
 (NEWID(),100022,109218,'',1000),
 (NEWID(),100023,109218,'',1000)
 */
 -- nhập vật tư
INSERT INTO dbo.[ITEM]([GUID],[CODE],[NAME],[IS_SUPPLIES])
SELECT NEWID(),ma_vt,ten_vt,1
FROM [FA11TQVAT].dbo.[dmvt]

-- nhập nguyên vật liệu

INSERT INTO dbo.[ITEM]([GUID],[CODE],[NAME],[IS_WOOD],[LENGTH],WIDTH,HEIGHT)
SELECT  NEWID(),NVL.CODE,NVL.[NAME],1,NVL.DAI,NVL.RONG,NVL.[DAY]
FROM(
	SELECT CODE,[NAME],DAI,RONG,[DAY]
	FROM NVL.[WoodslandNLG].dbo.[BOM]
	GROUP BY 	CODE,
				[NAME],
				DAI,
				RONG,
				[DAY]

) AS NVL

INSERT INTO dbo.[ITEM] ([GUID],CODE,[NAME],[IS_WOOD],[LENGTH],[WIDTH],[HEIGHT])
VALUES (NEWID(),'M',N'Mẫu',1,0,50,25)

INSERT INTO dbo.[ITEM]([GUID],[CODE],[NAME],IS_PRODUCT,CREATE_DATE)
VALUES 	(NEWID(),'O01',N'Tựa lưng cong (Bộ SP)',1,GETDATE()),
		(NEWID(),'O02',N'APPLARO Stool 63x63 (Bộ SP)',1,GETDATE()),
		(NEWID(),'O03',N'RUNNEN N floor dck 0,81 m² brown',1,GETDATE()),
		(NEWID(),'O04',N'RESÖ child picnic tbl grey-brown',1,GETDATE()),
		(NEWID(),'O05',N'ÄPPLARÖ bar stool/backr brown',1,GETDATE()),
		(NEWID(),'O06',N'ÄPPLARÖ bar table brown',1,GETDATE()),
		(NEWID(),'O07',N'ÄPPLARÖ gate-leg tbl f wll 80x59 brown',1,GETDATE()),
		(NEWID(),'O08',N'ÄPPLARÖ ufrm 77x50 brown',1,GETDATE()),
		(NEWID(),'O09',N'KLASEN N top shlf f ufrm 70x50 brown',1,GETDATE()),
		(NEWID(),'O10',N'ÄPPLARÖ wll panel 80x158 brown',1,GETDATE()),
		(NEWID(),'O11',N'ÄPPLARÖ bench brown',1,GETDATE()),
		(NEWID(),'O12',N'SOMMAR flower box 75x27',1,GETDATE()),
		(NEWID(),'O13',N'SOMMAR flower box 43x15',1,GETDATE()),
		(NEWID(),'O14',N'STACKHOLMEN stool, out 48x43',1,GETDATE()),
		(NEWID(),'I01',N'SKOGSTA bench 120 acacia (Bench 1200)',1,GETDATE()),
		(NEWID(),'I02',N'SKOGSTA wll shlf 120x25 acacia (Giá treo)',1,GETDATE()),
		(NEWID(),'I03',N'SKOGSTA tool box 40x20x23 acacia (Hộp đựng đồ)',1,GETDATE()),
		(NEWID(),'I04',N'SKOGSTA stool 39x45 acacia (Đôn 450)',1,GETDATE()),
		(NEWID(),'I05',N'SKOGSTA stool 48x70 acacia (Đôn 700)',1,GETDATE()),
		(NEWID(),'I06',N'SKOGSTA bench 60 acacia (Bench 600)',1,GETDATE()),
		(NEWID(),'I07',N'SKOGSTA chopping board 65x25 acacia (Thớt 650)',1,GETDATE()),
		(NEWID(),'I08',N'SKOGSTA chopping board 50x30 acacia (Thớt 500)',1,GETDATE()),
		(NEWID(),'I09',N'SKOGSTA chopping board 35x20 acacia (thớt 350)',1,GETDATE()),
		(NEWID(),'I10',N'SKOGSTA chr acacia (Ghế tựa)',1,GETDATE()),
		(NEWID(),'I11',N'SKOGSTA tray 35 acacia (Đĩa 350)',1,GETDATE()),
		(NEWID(),'I12',N'SKOGSTA dining tbl 235x105 acacia (BànN mới',1,GETDATE()),
		(NEWID(),'I13',N'SKOGSTA dining tbl 235x105 acacia (BànNN mới)',1,GETDATE()),
		(NEWID(),'I14',N'INTRESSANT spice mill 27 acacia',1,GETDATE()),
		(NEWID(),'I15',N' Chopping board 72x28',1,GETDATE()),
		(NEWID(),'I16',N'TYBYN bar table 74x74x102 acacia blach',1,GETDATE()),
		(NEWID(),'I17',N'STACKHOLMEN stool, out 48x43',1,GETDATE()),
		(NEWID(),'I18',N'HYLLEN floor decking 45x45',1,GETDATE()),
		(NEWID(),'I19',N'SKOGSTA table 160x81x74 acacia (Chân)',1,GETDATE())

INSERT INTO dbo.[ITEM]([GUID],[NAME],[CODE],IS_PRODUCT,CREATE_DATE)
VALUES 	(NEWID(),N'RUNNEN N floor deck, out 0.81 m² brown stained 9-p','O15',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ wall panel out 80x158 brown stained','O16',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ corner section, out brown stained','O17',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ one-seat sect, out brown stained','O18',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ tbl/stl sec, out 63x63 brown stained','O19',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ stool, out foldable brown stained','O20',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ chr w armrsts, out brown stained','O21',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ bench w backrest, out brown stained','O22',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ bar table, out brown stained','O23',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ gateleg tbl f wall 80x56 brown stained','O24',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ bar stool w backrst, out brown stained','O25',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ underframe out 77x58 brown stained','O26',1,GETDATE()),
		(NEWID(),N'KLASEN N top shlf f ufrm 70x50 brown stained','O27',1,GETDATE()),
		(NEWID(),N'RESÖ child picnic tbl grey-brown stained','O28',1,GETDATE()),
		(NEWID(),N'ÄPPLARÖ N chair out foldable brown stained','O29',1,GETDATE()),
		(NEWID(),N'STACKHOLMEN stool, out 48x43 grey-brown stained','O30',1,GETDATE()),
		(NEWID(),N'HOL side tbl 50x50 acacia','O31',1,GETDATE()),
		(NEWID(),N'HOL stor table 98x50 acacia','O32',1,GETDATE()),
		(NEWID(),N'SKOGSTA box w handle 40x20x23 acacia','O33',1,GETDATE()),
		(NEWID(),N'SKOGSTA serv stnd 35 acacia','O34',1,GETDATE()),
		(NEWID(),N'SKOGSTA stool 45 acacia','O35',1,GETDATE()),
		(NEWID(),N'SKOGSTA bar stool 48x70 acacia','O36',1,GETDATE()),
		(NEWID(),N'SKOGSTA bench 120 acacia','O37',1,GETDATE()),
		(NEWID(),N'SKOGSTA bench 60 acacia','O38',1,GETDATE()),
		(NEWID(),N'SKOGSTA wll shlf 120x25 acacia','O39',1,GETDATE()),
		(NEWID(),N'SKOGSTA chopping board 65x25 acacia ','O40',1,GETDATE()),
		(NEWID(),N'SKOGSTA chopping board 35x20 acacia ','O41',1,GETDATE()),
		(NEWID(),N'SKOGSTA chopping board 50x30 acacia','O42',1,GETDATE()),
		(NEWID(),N'SKOGSTA chr acacia ','O43',1,GETDATE()),
		(NEWID(),N'SMÅÄTA chopping board 72x28 acacia','O44',1,GETDATE()),
		(NEWID(),N'INTRESSANT spice mill 27 acacia','O45',1,GETDATE()),
		(NEWID(),N'TYBYN bar table 74x74x102 acacia/black','O46',1,GETDATE()),
		(NEWID(),N'HYLLEN floor decking 45x45 acacia','O47',1,GETDATE()),
		(NEWID(),N'SKOGSTA NN dining tbl 235x100 acacia','O48',1,GETDATE()),
		(NEWID(),N'SKOGSTA table 160x81x74 acacia','O49',1,GETDATE())
INSERT INTO dbo.[MARKET]([GUID],MARKET_NAME,MARKET_CODE,PRODUCT_CODE)
VALUES 	(NEWID(),N'RUNNEN N floor deck, out 0.81 m² brown stained 9-p','90234226','O15'),
		(NEWID(),N'RUNNEN N floor deck, out 0.81 m² brown stained 9-p AP CN','30234229','O15'),
		(NEWID(),N'ÄPPLARÖ wall panel out 80x158 brown stained','80204927','O16'),
		(NEWID(),N'ÄPPLARÖ wall panel out 80x158 brown stained AP CN','60204928','O16'),
		(NEWID(),N'ÄPPLARÖ wall panel out 80x158 brown stained RU','10376352','O16'),
		(NEWID(),N'ÄPPLARÖ corner section, out brown stained','50205179','O17'),
		(NEWID(),N'ÄPPLARÖ corner section, out brown stained AP JP','30205180','O17'),
		(NEWID(),N'ÄPPLARÖ corner section, out brown stained RU','40376336','O17'),
		(NEWID(),N'ÄPPLARÖ one-seat sect, out brown stained','60205188','O18'),
		(NEWID(),N'ÄPPLARÖ one-seat sect  out brown stained AP JP','40205189','O18'),
		(NEWID(),N'ÄPPLARÖ one-seat sect  out brown stained RU','20376342','O18'),
		(NEWID(),N'ÄPPLARÖ tbl/stl sec, out 63x63 brown stained','80213446','O19'),
		(NEWID(),N'ÄPPLARÖ tbl/stl sec, out 63x63 brown stained AP JP','00213445','O19'),
		(NEWID(),N'ÄPPLARÖ stool, out foldable brown stained','20204925','O20'),
		(NEWID(),N'ÄPPLARÖ stool, out foldable brown stained AP JP','00204926','O20'),
		(NEWID(),N'ÄPPLARÖ stool, out foldable brown stained RU','50376345','O20'),
		(NEWID(),N'ÄPPLARÖ chr w armrsts, out brown stained','20208527','O21'),
		(NEWID(),N'ÄPPLARÖ chr w armrsts, out brown stained AP JP','00208528','O21'),
		(NEWID(),N'ÄPPLARÖ chr w armrsts, out brown stained RU','60376335','O21'),
		(NEWID(),N'ÄPPLARÖ bench w backrest, out brown stained','80208529','O22'),
		(NEWID(),N'ÄPPLARÖ bench w backrest, out brown stained AP JP','60208530','O22'),
		(NEWID(),N'ÄPPLARÖ bench w backrest, out brown stained RU','30376332','O22'),
		(NEWID(),N'ÄPPLARÖ bar table, out brown stained','50288042','O23'),
		(NEWID(),N'ÄPPLARÖ bar table, out brown stained AP JP','30288043','O23'),
		(NEWID(),N'ÄPPLARÖ gateleg tbl f wall 80x56 brown stained','80291731','O24'),
		(NEWID(),N'ÄPPLARÖ gateleg tbl f wall 80x56 brown stained APJP','60291732','O24'),
		(NEWID(),N'ÄPPLARÖ bar stool w backrst, out brown stained','70288036','O25'),
		(NEWID(),N'ÄPPLARÖ bar stool w backrst, out brown stained AP JP','50288037','O25'),
		(NEWID(),N'ÄPPLARÖ bar stool w backrst, out brown stained RU','70376330','O25'),
		(NEWID(),N'ÄPPLARÖ underframe out 77x58 brown stained','90288040','O26'),
		(NEWID(),N'ÄPPLARÖ underframe out 77x58 brown stained AP CN','70288041','O26'),
		(NEWID(),N'ÄPPLARÖ underframe out 77x58 brown stained RU','30376351','O26'),
		(NEWID(),N'KLASEN N top shlf f ufrm 70x50 brown stained','70292694','O27'),
		(NEWID(),N'KLASEN N top shlf f ufrm 70x50 brown stained AP CN','90292693','O27'),
		(NEWID(),N'KLASEN N top shlf f ufrm 70x50 brown stained RU','80376117','O27'),
		(NEWID(),N'RESÖ child picnic tbl grey-brown stained','70228325','O28'),
		(NEWID(),N'RESÖ child picnic tbl grey-brown stained AP JP','50228326','O28'),
		(NEWID(),N'RESÖ child picnic tbl grey-brown stained RU','00376164','O28'),
		(NEWID(),N'ÄPPLARÖ N chair out foldable brown stained','40413131','O29'),
		(NEWID(),N'ÄPPLARÖ N chair out foldable brown stained RU','00413133','O29'),
		(NEWID(),N'STACKHOLMEN stool, out 48x43 grey-brown stained','20411425','O30'),
		(NEWID(),N'STACKHOLMEN stool, out 48x43 grey-brown stained AP','00411426','O30'),
		(NEWID(),N'STACKHOLMEN stool, out 48x43 grey-brown stained RU','50411424','O30'),
		(NEWID(),N'HOL side tbl 50x50 acacia','70161320','O31'),
		(NEWID(),N'HOL side tbl 50x50 acacia AP','90353021','O31'),
		(NEWID(),N'HOL stor table 98x50 acacia','50161321','O32'),
		(NEWID(),N'SKOGSTA box w handle 40x20x23 acacia','40297966','O33'),
		(NEWID(),N'SKOGSTA serv stnd 35 acacia','40309672','O34'),
		(NEWID(),N'SKOGSTA serv stnd 35 acacia AP','20309673','O34'),
		(NEWID(),N'SKOGSTA stool 45 acacia','10297958','O35'),
		(NEWID(),N'SKOGSTA stool 45 acacia AP JP','00305478 ','O35'),
		(NEWID(),N'SKOGSTA bar stool 48x70 acacia','70297955','O36'),
		(NEWID(),N'SKOGSTA bar stool 48x70 acacia APJP','80305479','O36'),
		(NEWID(),N'SKOGSTA bench 120 acacia','30297957','O37'),
		(NEWID(),N'SKOGSTA bench 60 acacia','50305428','O38'),
		(NEWID(),N'SKOGSTA wll shlf 120x25 acacia','10300499','O39'),
		(NEWID(),N'SKOGSTA chopping board 65x25 acacia ','40305424','O40'),
		(NEWID(),N'SKOGSTA chopping board 35x20 acacia ','60305423','O41'),
		(NEWID(),N'SKOGSTA chopping board 35x20 acacia APJP','10305500','O41'),
		(NEWID(),N'SKOGSTA chopping board 50x30 acacia','80305422','O42'),
		(NEWID(),N'SKOGSTA chr acacia ','90305426','O43'),
		(NEWID(),N'SKOGSTA chr acacia APJP','40305495','O43'),
		(NEWID(),N'SMÅÄTA chopping board 72x28 acacia','80320347','O44'),
		(NEWID(),N'SMÅÄTA chopping board 72x28 acacia APJP','60320348','O44'),
		(NEWID(),N'SMÅÄTA chopping board 72x28 acacia RU','10354227','O44'),
		(NEWID(),N'INTRESSANT spice mill 27 acacia','50301897','O45'),
		(NEWID(),N'INTRESSANT spice mill 27 acacia AP JP','30301898','O45'),
		(NEWID(),N'INTRESSANT spice mill 27 RU','90354228','O45'),
		(NEWID(),N'TYBYN bar table 74x74x102 acacia/black','00415622','O46'),
		(NEWID(),N'HYLLEN floor decking 45x45 acacia','80419918','O47'),
		(NEWID(),N'HYLLEN floor decking 45x45 acacia AP','20419935','O47'),
		(NEWID(),N'SKOGSTA NN dining tbl 235x100 acacia','70419264','O48'),
		(NEWID(),N'SKOGSTA NN dining tbl 235x100 acacia AP','40419265','O48'),
		(NEWID(),N'SKOGSTA NN dining tbl 235x100 acacia RU','20419266','O48'),
		(NEWID(),N'SKOGSTA table 160x81x74 acacia','00452643','O49'),
		(NEWID(),N'EKSOPP pot stand ext 21x15 acacia RU','20465866','O49')


-- nhập bán thành phẩm

INSERT INTO dbo.[ITEM]([GUID],[CODE],[NAME],IS_MATERIALS,[LENGTH],WIDTH,HEIGHT,CREATE_DATE)
VALUES 	(NEWID(),'O01.1',N'Thanh cong trái',1,760,58,19,GETDATE()),
		(NEWID(),'O01.2',N'Thanh cong phải',1,760,58,19,GETDATE()),
		(NEWID(),'O01.3',N'Nan tựa lưng to trên',1,550,58,19,GETDATE()),
		(NEWID(),'O01.4',N'Nan tựa lưng to giữa',1,550,58,19,GETDATE()),
		(NEWID(),'O01.5',N'Nan tựa lưng to dưới (3 lỗ)',1,550,58,19,GETDATE()),
		(NEWID(),'O01.6',N'Nan tựa lưng nhỏ',1,550,38,16,GETDATE()),
		(NEWID(),'O02.1',N'Đố mặt',1,626,58,19,GETDATE()),
		(NEWID(),'O02.2',N'Nan mặt ngoài',1,550,58,19,GETDATE()),
		(NEWID(),'O02.3',N'Nan mặt trong',1,550,58,16,GETDATE()),
		(NEWID(),'O02.4',N'Chân ghế R39',1,260,39,19,GETDATE()),
		(NEWID(),'O02.5',N'Chân ghế R58',1,260,58,19,GETDATE()),
		(NEWID(),'O02.8',N'Góc chân',1,58,59,23,GETDATE()),
		(NEWID(),'O02.6',N'Vai ghế không khoan',1,510,58,19,GETDATE()),
		(NEWID(),'O02.7',N'Vai ghế khoan (3 lỗ)',1,510,58,19,GETDATE()),
		(NEWID(),'O03.1',N'Thanh mặt 300x300',1,147.5,46.5,12,GETDATE()),
		(NEWID(),'O04.1',N'Nan mặt bàn trong',1,890,58,13,GETDATE()),
		(NEWID(),'O04.2',N'Nan mặt bàn ngoài',1,890,58,13,GETDATE()),
		(NEWID(),'O04.3',N'Đỡ mặt bàn ngoài',1,361,38,25,GETDATE()),
		(NEWID(),'O04.4',N'Đỡ mặt bàn giữa',1,347,58,13,GETDATE()),
		(NEWID(),'O04.5',N'Nan mặt ghế trong',1,890,58,15,GETDATE()),
		(NEWID(),'O04.6',N'Nan mặt ghế ngoài',1,890,58,15,GETDATE()),
		(NEWID(),'O04.7',N'Đỡ mặt ghế',1,161,58,13,GETDATE()),
		(NEWID(),'O04.8',N'Đỡ ghế ',1,912,38,25,GETDATE()),
		(NEWID(),'O04.9',N'Chân trái',1,571.2,90,15,GETDATE()),
		(NEWID(),'O04.10',N'Chân phải',1,571.2,90,15,GETDATE()),
		(NEWID(),'O05.1',N'Chân trước trái ',1,726,58,25,GETDATE()),
		(NEWID(),'O05.2',N'Chân nhỏ sau trái',1,450,58,25,GETDATE()),
		(NEWID(),'O05.3',N'Chân sau trái',1,660,58,25,GETDATE()),
		(NEWID(),'O05.4',N'Giằng hông trên',1,420,58,19,GETDATE()),
		(NEWID(),'O05.5',N'Giằng hông dưới',1,451,58,19,GETDATE()),
		(NEWID(),'O05.6',N'Chân trước phải',1,726,58,25,GETDATE()),
		(NEWID(),'O05.7',N'Chân nhỏ sau',1,450,58,25,GETDATE()),
		(NEWID(),'O05.8',N'Chân sau phải',1,660,58,25,GETDATE()),
		(NEWID(),'O05.9',N'Giằng hông trên',1,420,58,19,GETDATE()),
		(NEWID(),'O05.10',N'Giằng hông dưới',1,451,58,19,GETDATE()),
		(NEWID(),'O05.11',N'Nan mặt ngồi ngoài',1,316,58,19,GETDATE()),
		(NEWID(),'O05.12',N'Nan mặt ngồi trong',1,316,58,16,GETDATE()),
		(NEWID(),'O05.13',N'Nan mặt ngồi ngoài',1,284,58,19,GETDATE()),
		(NEWID(),'O05.14',N'Đố mặt ngồi',1,393.5,58,19,GETDATE()),
		(NEWID(),'O05.15',N'Đố mặt ngồi',1,393.5,58,19,GETDATE()),
		(NEWID(),'O05.16',N'Nan tựa giữa+dưới',1,314,38,16,GETDATE()),
		(NEWID(),'O05.17',N'Nan tựa trên',1,314,58,25,GETDATE()),
		(NEWID(),'O05.19',N'Giằng chân sau',1,324,58,19,GETDATE()),
		(NEWID(),'O06.1',N'Chân to phải',1,1026,58,25,GETDATE()),
		(NEWID(),'O06.2',N'Chân nhỏ phải',1,1026,37,25,GETDATE()),
		(NEWID(),'O06.3',N'Chân to trái',1,1026,58,25,GETDATE()),
		(NEWID(),'O06.4',N'Chân nhỏ trái',1,1026,37,25,GETDATE()),
		(NEWID(),'O06.5',N'Vai',1,581,58,25,GETDATE()),
		(NEWID(),'O06.6',N'Giằng chân trên trái',1,641,58,25,GETDATE()),
		(NEWID(),'O06.7',N'Giằng chân dưới trái',1,641,58,25,GETDATE()),
		(NEWID(),'O06.8',N'Giằng chân trên phải',1,641,58,19,GETDATE()),
		(NEWID(),'O06.9',N'Giằng chân dưới phải',1,641,58,19,GETDATE()),
		(NEWID(),'O06.10',N'Giằng chân giữa',1,653,58,19,GETDATE()),
		(NEWID(),'O06.11',N'Nan mặt bàn trong',1,621,58,16,GETDATE()),
		(NEWID(),'O06.12',N'Nan mặt bàn ngoài',1,621,58,19,GETDATE()),
		(NEWID(),'O06.13',N'Đố',1,697,58,19,GETDATE()),
		(NEWID(),'O07.1',N'Nan mặt trong',1,484,58,19,GETDATE()),
		(NEWID(),'O07.2',N'Năn mặt ngoài ',1,484,58,19,GETDATE()),
		(NEWID(),'O07.3',N'Đố mặt khoan',1,800,58,19,GETDATE()),
		(NEWID(),'O07.4',N'Đố mặt không khoan',1,800,58,19,GETDATE()),
		(NEWID(),'O07.5',N'Chân sau vế trái ',1,687,58,19,GETDATE()),
		(NEWID(),'O07.6',N'Chân sau vế phải ',1,687,58,19,GETDATE()),
		(NEWID(),'O07.7',N'Chân trước vế phải ',1,633,58,19,GETDATE()),
		(NEWID(),'O07.8',N'Chân trước vế trái  ',1,633,58,19,GETDATE()),
		(NEWID(),'O07.9',N'Giằng chân  phải',1,291.5,58,19,GETDATE()),
		(NEWID(),'O07.10',N'Giằng chân trái ',1,291.5,58,19,GETDATE()),
		(NEWID(),'O07.11',N'Thanh đỡ mặt',1,680,58,19,GETDATE()),
		(NEWID(),'O07.12',N'Thanh chống giữa',1,658,58,19,GETDATE()),
		(NEWID(),'O07.13',N'Chân ngang',1,360,58,19,GETDATE()),
		(NEWID(),'O08.1',N'Chân không bánh xe trái',1,870,58,19,GETDATE()),
		(NEWID(),'O08.2',N'Chân không bánh xe trái',1,870,43,19,GETDATE()),
		(NEWID(),'O08.3',N'Chân không bánh xe phải',1,870,58,19,GETDATE()),
		(NEWID(),'O08.4',N'Chân không bánh xe phải',1,870,43,19,GETDATE()),
		(NEWID(),'O08.5',N'Chân có bánh xe to trái',1,855,58,19,GETDATE()),
		(NEWID(),'O08.6',N'Chân có bánh xe nhỏ trái',1,855,43,19,GETDATE()),
		(NEWID(),'O08.7',N'Chân có bánh xe to phải',1,855,58,19,GETDATE()),
		(NEWID(),'O08.8',N'Chân có bánh xe nhỏ phải',1,855,43,19,GETDATE()),
		(NEWID(),'O08.9',N'Vai dài',1,584,58,19,GETDATE()),
		(NEWID(),'O08.10',N'Vai ngắn',1,384,58,19,GETDATE()),
		(NEWID(),'O08.11',N'Vai ngắn',1,384,58,19,GETDATE()),
		(NEWID(),'O08.12',N'Nan mặt trong ',1,424,38,16,GETDATE()),
		(NEWID(),'O08.13',N'Nan mặt ngoài',1,424,38,19,GETDATE()),
		(NEWID(),'O08.14',N'Đố ',1,660,38,19,GETDATE()),
		(NEWID(),'O08.15',N'Bánh xe',1,84,84,20,GETDATE()),
		(NEWID(),'O09.1',N'Đố mặt',1,700,58,25,GETDATE()),
		(NEWID(),'O09.2',N'Nan ngoài',1,424,58,25,GETDATE()),
		(NEWID(),'O09.3',N'Nan trong',1,424,58,19,GETDATE()),
		(NEWID(),'O10.1',N'Đố đứng trên (trái)',1,786,58,19,GETDATE()),
		(NEWID(),'O10.2',N'Đố đứng trên (phải)',1,786,58,19,GETDATE()),
		(NEWID(),'O10.3',N'Đố đứng dưới (trái)',1,786,58,19,GETDATE()),
		(NEWID(),'O10.4',N'Đố đứng dưới (phải)',1,786,58,19,GETDATE()),
		(NEWID(),'O10.5',N'Nan ngoài',1,724,58,19,GETDATE()),
		(NEWID(),'O10.6',N'Nan trong',1,724,38,16,GETDATE()),
		(NEWID(),'O11.1',N'Chân trước trái',1,587,58,25,GETDATE()),
		(NEWID(),'O11.2',N'Chân trước phải',1,587,58,25,GETDATE()),
		(NEWID(),'O11.3',N'Chân sau trái',1,548,58,25,GETDATE()),
		(NEWID(),'O11.4',N'Chân sau phải',1,548,58,25,GETDATE()),
		(NEWID(),'O11.5',N'Tay ghế',1,505,58,25,GETDATE()),
		(NEWID(),'O11.6',N'Giằng chân ghế',1,571,58,19,GETDATE()),
		(NEWID(),'O11.7',N'Đố mặt ghế',1,496,58,19,GETDATE()),
		(NEWID(),'O11.8',N'Nan ngoài mặt ghế',1,478,58,19,GETDATE()),
		(NEWID(),'O11.9',N'Nan trong mặt ghế',1,478,38,16,GETDATE()),
		(NEWID(),'O11.10',N'Đố tựa lưng ngoài ( cong)',1,410,58,19,GETDATE()),
		(NEWID(),'O11.11',N'Đố tựa lưng trong (cong )',1,323,58,19,GETDATE()),
		(NEWID(),'O11.12',N'Nan tựa lưng ngoài',1,974,58,19,GETDATE()),
		(NEWID(),'O11.13',N'Nan tựa lưng trong',1,478,38,16,GETDATE()),
		(NEWID(),'O11.14',N'Đỡ mặt ghế ',1,1080,58,25,GETDATE()),
		(NEWID(),'O11.15',N'Bọ đỡ mặt ghế',1,1014,28,19,GETDATE()),
		(NEWID(),'O12.1',N'Nan đáy',1,724,45,12,GETDATE()),
		(NEWID(),'O12.2',N'Đỡ nan đáy',1,245,30,15,GETDATE()),
		(NEWID(),'O12.3',N'Nan thành dài ngoài',1,725,60,12,GETDATE()),
		(NEWID(),'O12.4',N'Nan thành dài trong',1,725,45,12,GETDATE()),
		(NEWID(),'O12.5',N'Đỡ nan thành dài',1,228,30,15,GETDATE()),
		(NEWID(),'O12.6',N'Nan thành ngắn trên',1,270,60,12,GETDATE()),
		(NEWID(),'O12.7',N'Nan thành ngắn dưới',1,270,60,12,GETDATE()),
		(NEWID(),'O12.8',N'Nan thành ngắn trong',1,270,45,12,GETDATE()),
		(NEWID(),'O12.9',N'Đỡ nan thành ngắn',1,228,30,15,GETDATE()),
		(NEWID(),'O13.1',N'Nan đáy',1,404,60,12,GETDATE()),
		(NEWID(),'O13.2',N'Đỡ nan đáy',1,123,30,12,GETDATE()),
		(NEWID(),'O13.3',N'Nan thành dài',1,405,60,12,GETDATE()),
		(NEWID(),'O13.4',N'Đỡ nan thành dài',1,100,30,15,GETDATE()),
		(NEWID(),'O13.5',N'Nan thành ngắn',1,150,60,12,GETDATE()),
		(NEWID(),'O13.6',N'Đỡ nan thành ngắn',1,100,30,15,GETDATE()),
		(NEWID(),'O14.1',N'Đỡ mặt R922',1,475,77,32,GETDATE()),
		(NEWID(),'O14.2',N'Đỡ giằng mặt',1,331,48,32,GETDATE()),
		(NEWID(),'O14.3',N'Chân trái',1,393,48,32,GETDATE()),
		(NEWID(),'O14.4',N'Chân phải',1,393,48,32,GETDATE()),
		(NEWID(),'O14.5',N'Giằng chân',1,339,48,32,GETDATE()),
		(NEWID(),'I01.1',N'Mặt ghế',1,1200,142,18,GETDATE()),
		(NEWID(),'I01.2',N'Thanh Laptop đầu',1,60,124,18,GETDATE()),
		(NEWID(),'I01.3',N'Thanh Laptop cạnh',1,1200,20,18,GETDATE()),
		(NEWID(),'I01.4',N'Vai dài',1,979,58,18,GETDATE()),
		(NEWID(),'I01.5',N'Vai ngăn',1,160,58,18,GETDATE()),
		(NEWID(),'I01.6',N'Giằng giữa',1,170,58,18,GETDATE()),
		(NEWID(),'I01.7',N'Chân',1,452,40,40,GETDATE()),
		(NEWID(),'I02.1',N'Tấm treo tường',1,1200,245,18,GETDATE()),
		(NEWID(),'I02.2',N'Tấm giá đỡ',1,1200,227,18,GETDATE()),
		(NEWID(),'I03.1',N'Thành Dài',1,368,115,10,GETDATE()),
		(NEWID(),'I03.2',N'Thanh Góc tam giác',1,100,42,21.21,GETDATE()),
		(NEWID(),'I03.3',N'Thành Ngắn',1,228,200,16,GETDATE()),
		(NEWID(),'I03.4',N'Tay Sách',1,391,20,20,GETDATE()),
		(NEWID(),'I03.5',N'Đáy',1,375,184,10,GETDATE()),
		(NEWID(),'I04.1',N'Mặt',1,280,280,36,GETDATE()),
		(NEWID(),'I04.2',N'Chân',1,441,32,32,GETDATE()),
		(NEWID(),'I04.3',N'Bọ góc tam giác',1,85,37,25,GETDATE()),
		(NEWID(),'I04.4',N'Giàng dương',1,277,40,25,GETDATE()),
		(NEWID(),'I04.5',N'Giàng âm',1,277,40,25,GETDATE()),
		(NEWID(),'I05.1',N'Mặt',1,280,280,36,GETDATE()),
		(NEWID(),'I05.2',N'Chân',1,694,32,32,GETDATE()),
		(NEWID(),'I05.3',N'Bọ góc tam giác',1,85,37,25,GETDATE()),
		(NEWID(),'I05.4',N'Giàng dương',1,319,40,25,GETDATE()),
		(NEWID(),'I05.5',N'Giàng âm',1,319,40,25,GETDATE()),
		(NEWID(),'I06.1',N'Mặt',1,660,142,18,GETDATE()),
		(NEWID(),'I06.2',N'Thanh Laptop đầu',1,30,124,18,GETDATE()),
		(NEWID(),'I06.3',N'Thanh Laptop cạnh',1,600,20,18,GETDATE()),
		(NEWID(),'I06.4',N'Vai dài',1,464,58,18,GETDATE()),
		(NEWID(),'I06.5',N'Vai Ngắn',1,160,58,18,GETDATE()),
		(NEWID(),'I06.6',N'Chân',1,452,40,40,GETDATE()),
		(NEWID(),'I07.1',N'Tấm Thớt',1,635,250,25,GETDATE()),
		(NEWID(),'I08.1',N'Tấm Thớt',1,500,300,25,GETDATE()),
		(NEWID(),'I09.1',N'Tấm Thớt',1,350,200,25,GETDATE()),
		(NEWID(),'I10.1',N'Nan mặt ghế trước',1,445,190,18,GETDATE()),
		(NEWID(),'I10.2',N'Nan mặt ghế sau',1,414,190,18,GETDATE()),
		(NEWID(),'I10.3',N'Nan Tựa lưng',1,400,190,18,GETDATE()),
		(NEWID(),'I10.4',N'Chân sau trên',1,153,32,32,GETDATE()),
		(NEWID(),'I10.5',N'Chân sau dưới trái',1,627,32,32,GETDATE()),
		(NEWID(),'I10.6',N'Chân sau dưới phải',1,627,32,32,GETDATE()),
		(NEWID(),'I10.7',N'Chân trước trái',1,461,32,32,GETDATE()),
		(NEWID(),'I10.8',N'Chân trước phải',1,461,32,32,GETDATE()),
		(NEWID(),'I10.9',N'Giằng trên',1,380,40,28,GETDATE()),
		(NEWID(),'I10.10',N'Giằng dưới vế phải',1,423,32,28,GETDATE()),
		(NEWID(),'I10.11',N'Giằng dưới vế trái',1,423,32,28,GETDATE()),
		(NEWID(),'I10.12',N'Giằng giữa',1,312,32,28,GETDATE()),
		(NEWID(),'I11.1',N'Mặt',1,350,350,25,GETDATE()),
		(NEWID(),'I11.2',N'Chân',1,103,32,25,GETDATE()),
		(NEWID(),'I12.1',N'Mặt bàn (dày 38)',1,2350,500,38,GETDATE()),
		(NEWID(),'I12.2',N'Mặt bàn  AC (19)',1,2350,500,19,GETDATE()),
		(NEWID(),'I12.3',N'Mặt bàn  BC (19)',1,2350,500,19,GETDATE()),
		(NEWID(),'I13.4',N'Chân trái',1,725,70,70,GETDATE()),
		(NEWID(),'I13.5',N'Chân phải',1,725,70,70,GETDATE()),
		(NEWID(),'I13.6',N'Giằng ngang',1,2100,70,50,GETDATE()),
		(NEWID(),'I13.7',N'Giằng chéo',1,962,70,50,GETDATE()),
		(NEWID(),'I13.8',N'Giằng chân dưới',1,817,75,60,GETDATE()),
		(NEWID(),'I13.9',N'Giằng chân trên',1,745,75,60,GETDATE()),
		(NEWID(),'I13.10',N'Mộng giả',1,60,30,30,GETDATE()),
		(NEWID(),'I13.11',N'Nêm chân',1,113,31,10,GETDATE()),
		(NEWID(),'I14.1',N'Thân',1,202,66,66,GETDATE()),
		(NEWID(),'I14.2',N'Nắp',1,73,56,56,GETDATE()),
		(NEWID(),'I15.1',N'Tấm thớt',1,717,280,20,GETDATE()),
		(NEWID(),'I16.1',N'Mặt bàn ',1,740,367.5,30,GETDATE()),
		(NEWID(),'I16.2',N'Chân bàn trái',1,1001,55,55,GETDATE()),
		(NEWID(),'I16.3',N'Chân bàn phải',1,1001,55,55,GETDATE()),
		(NEWID(),'I16.4',N'Vai trước,sau',1,436,70,19,GETDATE()),
		(NEWID(),'I16.5',N'Vai trái,pải',1,436,70,19,GETDATE()),
		(NEWID(),'I16.6',N'Giằng chân',1,591.5,55,30,GETDATE()),
		(NEWID(),'I16.7',N'Giằng ngang',1,740,55,30,GETDATE()),
		(NEWID(),'I18.1',N'Nan mặt',1,450,45.5,12,GETDATE()),
		(NEWID(),'I18.2',N'Giằng',1,430,45.5,12,GETDATE()),
		(NEWID(),'I19.1',N'Mặt bàn',1,1600,400,38,GETDATE()),
		(NEWID(),'I19.2',N'Chân trái',1,725,60,60,GETDATE()),
		(NEWID(),'I19.3',N'Chân phải',1,725,60,60,GETDATE()),
		(NEWID(),'I19.4',N'Giằng ngang',1,1409,60,44,GETDATE()),
		(NEWID(),'I19.5',N'Giằng chéo',1,664,60,50,GETDATE()),
		(NEWID(),'I19.6',N'Giằng chân dưới',1,614,60,50,GETDATE()),
		(NEWID(),'I19.7',N'Giằng chân trên',1,542,60,50,GETDATE()),
		(NEWID(),'I19.8',N'Mộng giả',1,60,30,30,GETDATE()),
		(NEWID(),'I19.9',N'Nêm chân',1,113,31,10,GETDATE())

CREATE TABLE #TEMP_BOM(
	ITEM_CODE VARCHAR(50),
	RATIO MONEY
)

INSERT INTO #TEMP_BOM(ITEM_CODE,RATIO)
VALUES 	('O01.1',1),
		('O01.2',1),
		('O01.3',1),
		('O01.4',1),
		('O01.5',1),
		('O01.6',5),
		('O02.1',2),
		('O02.2',2),
		('O02.3',7),
		('O02.4',4),
		('O02.5',4),
		('O02.8',4),
		('O02.6',3),
		('O02.7',1),
		('O03.1',108),
		('O04.1',4),
		('O04.2',2),
		('O04.3',2),
		('O04.4',1),
		('O04.5',2),
		('O04.6',4),
		('O04.7',6),
		('O04.8',2),
		('O04.9',2),
		('O04.10',2),
		('O05.1',1),
		('O05.2',1),
		('O05.3',1),
		('O05.4',1),
		('O05.5',1),
		('O05.6',1),
		('O05.7',1),
		('O05.8',1),
		('O05.9',1),
		('O05.10',1),
		('O05.11',1),
		('O05.12',4),
		('O05.13',1),
		('O05.14',1),
		('O05.15',1),
		('O05.16',4),
		('O05.17',3),
		('O05.19',2),
		('O06.1',2),
		('O06.2',2),
		('O06.3',2),
		('O06.4',2),
		('O06.5',2),
		('O06.6',1),
		('O06.7',2),
		('O06.8',1),
		('O06.9',1),
		('O06.10',1),
		('O06.11',8),
		('O06.12',2),
		('O06.13',2),
		('O07.1',9),
		('O07.2',2),
		('O07.3',1),
		('O07.4',1),
		('O07.5',1),
		('O07.6',1),
		('O07.7',1),
		('O07.8',1),
		('O07.9',2),
		('O07.10',2),
		('O07.11',1),
		('O07.12',1),
		('O07.13',1),
		('O08.1',1),
		('O08.2',1),
		('O08.3',1),
		('O08.4',1),
		('O08.5',1),
		('O08.6',1),
		('O08.7',1),
		('O08.8',1),
		('O08.9',2),
		('O08.10',1),
		('O08.11',1),
		('O08.12',10),
		('O08.13',2),
		('O08.14',2),
		('O08.15',2),
		('O09.1',2),
		('O09.2',2),
		('O09.3',9),
		('O10.1',1),
		('O10.2',1),
		('O10.3',1),
		('O10.4',1),
		('O10.5',1),
		('O10.6',16),
		('O11.1',1),
		('O11.2',1),
		('O11.3',1),
		('O11.4',1),
		('O11.5',2),
		('O11.6',2),
		('O11.7',3),
		('O11.8',4),
		('O11.9',14),
		('O11.10',2),
		('O11.11',1),
		('O11.12',2),
		('O11.13',8),
		('O11.14',2),
		('O11.15',2),
		('O12.1',4),
		('O12.2',3),
		('O12.3',4),
		('O12.4',4),
		('O12.5',4),
		('O12.6',2),
		('O12.7',2),
		('O12.8',4),
		('O12.9',4),
		('O13.1',2),
		('O13.2',2),
		('O13.3',4),
		('O13.4',4),
		('O13.5',4),
		('O13.6',4),
		('O14.1',2),
		('O14.2',2),
		('O14.3',2),
		('O14.4',2),
		('O14.5',2),
		('I01.1',2),
		('I01.2',4),
		('I01.3',2),
		('I01.4',2),
		('I01.5',2),
		('I01.6',1),
		('I01.7',4),
		('I02.1',1),
		('I02.2',1),
		('I03.1',2),
		('I03.2',4),
		('I03.3',2),
		('I03.4',1),
		('I03.5',1),
		('I04.1',1),
		('I04.2',4),
		('I04.3',4),
		('I04.4',1),
		('I04.5',1),
		('I05.1',1),
		('I05.2',4),
		('I05.3',4),
		('I05.4',1),
		('I05.5',1),
		('I06.1',2),
		('I06.2',4),
		('I06.3',2),
		('I06.4',2),
		('I06.5',2),
		('I06.6',4),
		('I07.1',1),
		('I08.1',1),
		('I09.1',1),
		('I10.1',1),
		('I10.2',1),
		('I10.3',1),
		('I10.4',2),
		('I10.5',1),
		('I10.6',1),
		('I10.7',1),
		('I10.8',1),
		('I10.9',2),
		('I10.10',1),
		('I10.11',1),
		('I10.12',1),
		('I11.1',1),
		('I11.2',3),
		('I12.1',2),
		('I12.2',2),
		('I12.3',2),
		('I13.4',2),
		('I13.5',2),
		('I13.6',1),
		('I13.7',2),
		('I13.8',2),
		('I13.9',2),
		('I13.10',4),
		('I13.11',4),
		('I14.1',1),
		('I14.2',1),
		('I15.1',1),
		('I16.1',2),
		('I16.2',2),
		('I16.3',2),
		('I16.4',2),
		('I16.5',2),
		('I16.6',2),
		('I16.7',1),
		('O14.1',2),
		('O14.2',2),
		('O14.3',2),
		('O14.4',2),
		('O14.5',2),
		('I18.1',9),
		('I18.2',3),
		('I19.1',2),
		('I19.2',2),
		('I19.3',2),
		('I19.4',1),
		('I19.5',2),
		('I19.6',2),
		('I19.7',2),
		('I19.8',4),
		('I19.9',4)

INSERT INTO dbo.[BOM]([GUID],ITEM_ID,MATERIALS_ID,RATE)
SELECT NEWID(),I2.ID,I1.ID,TB.RATIO
FROM #TEMP_BOM TB
LEFT JOIN dbo.[ITEM] I1 ON I1.CODE = TB.ITEM_CODE
LEFT JOIN dbo.[ITEM] I2 ON I2.CODE = LEFT(TB.ITEM_CODE,3)

DROP TABLE #TEMP_BOM


--SELECT * FROM dbo.[ROUTING]
--TRUNCATE TABLE dbo.[ROUTING]
INSERT INTO dbo.[ROUTING]([GUID],ITEM_ID,STEP_ID,[ORDER])
VALUES 	(NEWID(),109665,100024,1),
		(NEWID(),109679,100072,1),
(NEWID(),109733,100007,1),
(NEWID(),109733,100008,2),
(NEWID(),109733,100010,3),
(NEWID(),109733,100012,4),
(NEWID(),109733,100015,5),
(NEWID(),109733,100024,6),
(NEWID(),109738,100007,1),
(NEWID(),109738,100008,2),
(NEWID(),109738,100010,3),
(NEWID(),109738,100012,4),
(NEWID(),109738,100015,5),
(NEWID(),109738,100024,6),
(NEWID(),109861,100053,1),
(NEWID(),109861,100054,2),
(NEWID(),109861,100055,3),
(NEWID(),109861,100056,4),
(NEWID(),109861,100057,5),
(NEWID(),109861,100072,6),
(NEWID(),109862,100053,1),
(NEWID(),109862,100054,2),
(NEWID(),109862,100055,3),
(NEWID(),109862,100056,4),
(NEWID(),109862,100057,5),
(NEWID(),109862,100072,6)


INSERT INTO dbo.[WORK_RESOURCES]([GUID],CODE,[NAME])
VALUES (NEWID(),'MC',N'Máy cắt'),
(NEWID(),'MB',N'Máy bào'),
(NEWID(),'MP',N'Máy phay'),
(NEWID(),'MK',N'Máy khoan')

INSERT INTO base.ITEM_TYPE (GUID,CODE,NAME)
VALUES (NEWID(),'S',N'Vật tư'),
(NEWID(),'W',N'Gỗ thô'),
(NEWID(),'M',N'Bán thành phẩm/chi tiết/cụm'),
(NEWID(),'P',N'Thành phẩm')



END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT
EXEC Proc_createKilnBatch
100000,
5,
100000,
@ERROR = @E OUTPUT
*/


CREATE   PROC [dbo].[Proc_createKilnBatch]
@KILN_ID INT,
@STEP_NEXT_ID INT,
@TARGET INT,
@LENGTH INT,
@HEIGHT NVARCHAR(50),
@TYPE NVARCHAR(200),
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	SET XACT_ABORT ON
	BEGIN TRANSACTION 
	update base.ACCOUNT set updatedAt = GETDATE() where id = @ACCOUNT_ID
	DECLARE @KILN_BATCH_NUMBER INT
	DECLARE @KILN_BATCH_GUID UNIQUEIDENTIFIER = NEWID()

	IF EXISTS (
			SELECT ID FROM prod.[KILN_BATCH]
			WHERE KILN_ID = @KILN_ID
			AND TIME_OUT_REAL IS NULL
	)
	BEGIN
		SET @ERROR = 420
		ROLLBACK
		RETURN
	END


	SELECT @KILN_BATCH_NUMBER = MAX([NUMBER])
	FROM prod.[KILN_BATCH]
	WHERE [YEAR] = YEAR(GETDATE())
	AND [WEEK] = DATEPART(WK,GETDATE())

	IF @KILN_BATCH_NUMBER IS NULL
		BEGIN
			SET @KILN_BATCH_NUMBER = 1
		END
	ELSE
		BEGIN
			SET @KILN_BATCH_NUMBER = @KILN_BATCH_NUMBER + 1
		END



	INSERT INTO prod.[KILN_BATCH]([GUID],NUMBER,[WEEK],[YEAR],KILN_ID,STEP_NEXT_ID,TIME_OUT_TARGET,[LENGTH],[HEIGHT],[TYPE],[STATUS],CREATE_BY,CREATE_DATE)
	VALUES(@KILN_BATCH_GUID,@KILN_BATCH_NUMBER,DATEPART(WK,GETDATE()),YEAR(GETDATE()),@KILN_ID,@STEP_NEXT_ID,@TARGET,@LENGTH,@HEIGHT,@TYPE,'created',@ACCOUNT_ID,GETDATE())

	SELECT ID 
	FROM prod.[KILN_BATCH]
	WHERE [GUID] = @KILN_BATCH_GUID

	COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createPackage]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_createPackage]
    @FROM_ID INT,
    @TO_ID INT,
    @ITEM_FROM_ID INT,
    @ITEM_ID INT,
    @QUANTITY decimal(19, 6),
    @MATERIALS_ID INT,
    @MATERIALS_QUANTITY decimal(19, 6),
    @TYPE_ID INT,
    @REMEDIES_ID INT,
    @DESCRIPTION NVARCHAR(1000),
    @PO char(36),
    @ACCOUNT_ID INT,
    @ERROR INT OUTPUT
AS
BEGIN
    SET XACT_ABORT ON
	--if(@QUANTITY <=0 )
	--BEGIN
 --       SET @ERROR = 4505
 --       RETURN
 --   END
	--update prod.PACKAGE set VERIFY_DATE = GETDATE() where VERIFY_DATE is null
	update prod.PO set ton=xuatTon where xuatTon > ton and endPO = 0
    BEGIN TRANSACTION
    DECLARE @PACKAGE_ID INT
    DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
    DECLARE @ITEM_IN_PACKAGE_ID INT
    DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
    DECLARE @DATHUCHIEN decimal(19, 6)
	DECLARE @TONCONLAI decimal(19, 6)
	Declare @ConTon decimal(19,6)
	Declare @Ton decimal(19,6)
    select @DATHUCHIEN = sum(iip.QUANTITY)
    from prod.ITEM_IN_PACKAGE iip left join prod.PACKAGE p on p.ID = iip.PACKAGE_ID
    where p.PO = @PO and p.TYPE_ID = 100026 

    DECLARE @KEHOACH decimal(19, 6), @LOI decimal(19, 6), @DAXUATTON decimal(19, 6),@factoryId INT

    select @KEHOACH = keHoach + hanMucTon + loiCongDon - soLuongUuTien - ys1a - ys1b -ys4 - th + xuatTon - @DATHUCHIEN , @LOI = loiCongDon, @Ton = ton, @TONCONLAI = ton - xuatTon, @DAXUATTON = xuatTon, @factoryId = factoryId
    from prod.PO
    where code = @PO

	if(@KEHOACH < 0)
	set @KEHOACH = 0
	if(@ConTon) < 0 set @ConTon = 0

    declare @LENHSX nvarchar(200)

    select @LENHSX=p.number
    from prod.PO p left join prod.PACKAGE pa on p.code = pa.PO
    where code = @PO

 --   if(@TYPE_ID != 100004 AND @QUANTITY > @KEHOACH + @TONCONLAI)
	--BEGIN
 --       ROLLBACK
 --       SET @ERROR = 4505
 --       RETURN
 --   END

    --update base.ACCOUNT set updatedAt = GETDATE() where id = @ACCOUNT_ID

    INSERT INTO prod.[PACKAGE]
        ([GUID],SOURCE_ID,DESTINATION_ID,ITEM_FROM_ID,[TYPE_ID],REMEDIES_ID,[DESCRIPTION],CREATE_BY,CREATE_DATE, PO)
    VALUES(@PACKAGE_GUID, @FROM_ID, @TO_ID, @ITEM_FROM_ID, @TYPE_ID, @REMEDIES_ID, @DESCRIPTION, @ACCOUNT_ID, GETDATE(), @PO)
    SELECT @PACKAGE_ID = ID
    FROM prod.[PACKAGE]
    WHERE [GUID] = @PACKAGE_GUID

    INSERT INTO prod.[ITEM_IN_PACKAGE]
        ([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
    VALUES(@ITEM_IN_PACKAGE_GUID, @PACKAGE_ID, @ITEM_ID, @QUANTITY)
    SELECT @ITEM_IN_PACKAGE_ID = ID
    FROM prod.[ITEM_IN_PACKAGE]
    WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

    IF (@MATERIALS_ID IS NULL)
		BEGIN
        SET @MATERIALS_ID = @ITEM_ID
    END
    IF(@MATERIALS_QUANTITY IS NULL)
		BEGIN
        SET @MATERIALS_QUANTITY = @QUANTITY-@TONCONLAI
    END

		IF(@QUANTITY < @TONCONLAI)
		BEGIN
			UPDATE prod.PO set xuatTon = xuatTon + @QUANTITY where code = @PO
		END
	ELSE
		BEGIN
			UPDATE prod.PO set xuatTon = xuatTon + @TONCONLAI where code = @PO
		END
	IF @MATERIALS_QUANTITY > 0
	BEGIN
    IF EXISTS (
		select B.ID
    from prod.BOM B
    where B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
	)
		BEGIN
        IF EXISTS (
				SELECT R.ID
        from prod.ROUTING R
        where R.[ORDER] = 1
            and R.ITEM_ID = @ITEM_ID
            and R.STEP_ID = @FROM_ID
			and R.factoryId = @factoryId
			) -- Tại công đoạn đầu tiên sẽ lấy theo định mức
				BEGIN
            INSERT INTO prod.MATERIALS_IN_PACKAGE
                (GUID,ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
            SELECT NEWID(), @ITEM_IN_PACKAGE_ID, B.MATERIALS_ID, (@QUANTITY-@TONCONLAI) * B.RATE
            FROM prod.BOM B
            WHERE B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
        END
			ELSE
				BEGIN
            INSERT INTO prod.[MATERIALS_IN_PACKAGE]
                ([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
            VALUES(NEWID(), @ITEM_IN_PACKAGE_ID, @MATERIALS_ID, @MATERIALS_QUANTITY)
        END
    END
	ELSE
		BEGIN
        INSERT INTO prod.[MATERIALS_IN_PACKAGE]
            ([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
        VALUES(NEWID(), @ITEM_IN_PACKAGE_ID, @MATERIALS_ID, @MATERIALS_QUANTITY)
    END
    END
--	IF(@TONCONLAI < @QUANTITY)
--	BEGIN
--	IF @FROM_ID not in (select ID FROM [base].[DEPARTMENT] where TYPE2 = 'department') and EXISTS (
--		select ITEM_ID, SUM(quantity) as ton
--        from (
--                            select iip.ITEM_ID, sum(iip.QUANTITY) as quantity
--                from prod.ITEM_IN_PACKAGE iip
--                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
--                    left join prod.PO po on po.code = p.PO
--                where DESTINATION_ID = @FROM_ID and p.VERIFY_DATE is not null and p.TYPE_ID = 100026 and p.PO is not null
--				and po.endPO = 0 and po.approvedAt is not null and po.deletedAt is null
--				--and p.PO in (select code from prod.PO where deletedAt is null and approvedAt is not null and endPo = 0 ) --and (po.number = @LENHSX or @FROM_ID in (select ID from base.DEPARTMENT where NAME like N'%đóng gói%' and TYPE2 = 'department')) and p.VERIFY_DATE is not null and p.TYPE_ID = 100026
--                group by iip.ITEM_ID

--            UNION ALL

--                select m.ITEM_ID, -sum(m.QUANTITY) as quantity
--                from prod.MATERIALS_IN_PACKAGE m
--                    left join prod.ITEM_IN_PACKAGE iip on m.ITEM_IN_PACKAGE_ID = iip.ID
--                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
--                    left join prod.PO po on po.code = p.PO
--                where SOURCE_ID = @FROM_ID and p.PO is not null 
--				and po.endPO = 0 and po.approvedAt is not null and po.deletedAt is null
--				--and p.PO in (select code from prod.PO where deletedAt is null and approvedAt is not null and endPo = 0 ) --and (po.number = @LENHSX or @FROM_ID in (select ID from base.DEPARTMENT where NAME like N'%đóng gói%' and TYPE2 = 'department'))
--                group by m.ITEM_ID
--		) as x
--        group by ITEM_ID
--        having SUM(quantity) < 0 and (ITEM_ID = @ITEM_ID or ITEM_ID in(
--	select B.MATERIALS_ID
--            from prod.BOM B
--            where B.ITEM_ID = @ITEM_ID
--))
--	)
--	BEGIN
--        ROLLBACK
--        SET @ERROR = 4502
--        RETURN
--    END
--    END
	COMMIT

    -- Trả về thông tin package
	--update prod.PO set market = null where stepId in (100269,100272,100279) and status is null
	--update prod.PO set quantity = keHoach where quantity = 0
    SELECT
        P.ID id
    FROM prod.PACKAGE P
    WHERE P.[ID] = @PACKAGE_ID



    -- Trả về thông tin package
    SELECT
        P.ID packageId,
        P.SOURCE_ID fromId,
        P.DESTINATION_ID toId,
        P.CREATE_BY createBy,
        P.CREATE_DATE createDate
    FROM prod.PACKAGE P
    WHERE P.[ID] = @PACKAGE_ID
    -- Trả về thông tin item trong package
    SELECT
        P.ID packageId,
        IIP.ID itemInPackageId,
        IIP.ITEM_ID itemId,
        IIP.QUANTITY quantity
    FROM prod.PACKAGE P
        LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
    WHERE P.ID = @PACKAGE_ID
    -- Trả về nguyên liệu của pallet này
    SELECT
        IIP.ID itemInPackageId,
        MIP.ID materialsInPackageId,
        MIP.ITEM_ID itemId,
        MIP.QUANTITY quantity
    FROM prod.PACKAGE P
        LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
        LEFT JOIN prod.MATERIALS_IN_PACKAGE MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
    WHERE P.ID = @PACKAGE_ID
	--update prod.PACKAGE set VERIFY_DATE = GETDATE() where VERIFY_DATE is null
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createPackage_1]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[Proc_createPackage_1]
    @FROM_ID INT,
    @TO_ID INT,
    @ITEM_FROM_ID INT,
    @ITEM_ID INT,
    @QUANTITY decimal(19, 6),
	@TONCONLAI decimal(19, 6),
    @MATERIALS_ID INT,
    @MATERIALS_QUANTITY decimal(19, 6),
    @TYPE_ID INT,
    @REMEDIES_ID INT,
    @DESCRIPTION NVARCHAR(1000),
    @PO char(36),
    @ACCOUNT_ID INT,
    @ERROR INT OUTPUT
AS
BEGIN
    SET XACT_ABORT ON
    BEGIN TRANSACTION
    DECLARE @PACKAGE_ID INT
    DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
    DECLARE @ITEM_IN_PACKAGE_ID INT
    DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
    DECLARE @DATHUCHIEN decimal(19, 6)
	--DECLARE @TONCONLAI decimal(19, 6)
    select @DATHUCHIEN = sum(iip.QUANTITY)
    from prod.ITEM_IN_PACKAGE iip left join prod.PACKAGE p on p.ID = iip.PACKAGE_ID
    where p.PO = @PO and p.TYPE_ID = 100026 

    DECLARE @KEHOACH decimal(19, 6),@dem int, @LOI decimal(19, 6), @DAXUATTON decimal(19, 6), @factoryId INT, @number NVARCHAR(1000),@VOLUMN float, @hanmucton decimal(19, 6),@NEXT_STEP_ID INT,@NEXT_ITEM_ID INT,@NITEM_ID INT,@VOLUMN1 float,@VOLUMN2 float,@NITEM_ID1 INT,@VOLUMN3 float,@NITEM_ID3 INT

    select @KEHOACH = keHoach , @LOI = loiCongDon, @DAXUATTON = xuatTon, @factoryId = factoryId,@number = number
    from prod.PO
    where code = @PO
	select @NEXT_ITEM_ID = NEXT_ITEM_ID,@VOLUMN= VOLUMN from base.ITEM where ID = @ITEM_ID
	IF( @NEXT_ITEM_ID is not null)
	BEGIN
	select TOP (1) @NITEM_ID = ID,@VOLUMN1 = VOLUMN from base.ITEM where ID <> @ITEM_ID and NEXT_ITEM_ID = @NEXT_ITEM_ID and NEXT_STEP_ID is null
	order by ID
	
	select @dem = COUNT(ID) from base.ITEM where ID <> @ITEM_ID and NEXT_ITEM_ID = @NEXT_ITEM_ID and NEXT_STEP_ID is null
	END
	IF(@VOLUMN is not null  and @NEXT_ITEM_ID is not null)
	BEGIN
	
	select @NITEM_ID1 = ID,@VOLUMN2 = VOLUMN,@NEXT_STEP_ID = NEXT_STEP_ID  from base.ITEM where ID <> @ITEM_ID and NEXT_ITEM_ID = @NEXT_ITEM_ID and NEXT_STEP_ID is not null
	END
	IF(@VOLUMN = 1 and @dem =2 and @NEXT_ITEM_ID is not null)
	BEGIN
	
	select TOP 1 @NITEM_ID3 = ID,@VOLUMN3 = VOLUMN from base.ITEM where ID <> @ITEM_ID and NEXT_ITEM_ID = @NEXT_ITEM_ID and NEXT_STEP_ID is null
	order by ID DESC
	END
    declare @LENHSX nvarchar(200)

    select @LENHSX=p.number
    from prod.PO p left join prod.PACKAGE pa on p.code = pa.PO
    where code = @PO

 --   if(@QUANTITY + @DATHUCHIEN > @KEHOACH + @LOI)
	--BEGIN
 --       ROLLBACK
 --       SET @ERROR = 4505
 --       RETURN
 --   END

    update base.ACCOUNT set updatedAt = GETDATE() where id = @ACCOUNT_ID

    INSERT INTO prod.[PACKAGE]
        ([GUID],SOURCE_ID,DESTINATION_ID,ITEM_FROM_ID,[TYPE_ID],REMEDIES_ID,[DESCRIPTION],CREATE_BY,CREATE_DATE, PO,factoryId)
    VALUES(@PACKAGE_GUID, @FROM_ID, @TO_ID, @ITEM_FROM_ID, @TYPE_ID, @REMEDIES_ID, @DESCRIPTION, @ACCOUNT_ID, GETDATE(), @PO,@factoryId)
    SELECT @PACKAGE_ID = ID
    FROM prod.[PACKAGE]
    WHERE [GUID] = @PACKAGE_GUID

    INSERT INTO prod.[ITEM_IN_PACKAGE]
        ([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
    VALUES(@ITEM_IN_PACKAGE_GUID, @PACKAGE_ID, @ITEM_ID, @QUANTITY)
    SELECT @ITEM_IN_PACKAGE_ID = ID
    FROM prod.[ITEM_IN_PACKAGE]
    WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

    IF (@MATERIALS_ID IS NULL)
		BEGIN
        SET @MATERIALS_ID = @ITEM_ID
    END
    IF(@MATERIALS_QUANTITY IS NULL)
		BEGIN
        SET @MATERIALS_QUANTITY = @QUANTITY-@TONCONLAI
    END

		IF(@QUANTITY < @TONCONLAI)
		BEGIN
			UPDATE prod.PO set xuatTon = xuatTon + @QUANTITY where code = @PO
		END
	ELSE
		BEGIN
			UPDATE prod.PO set xuatTon = xuatTon + @TONCONLAI where code = @PO
		END
	IF @MATERIALS_QUANTITY > 0
	BEGIN
    IF EXISTS (
		select B.ID
    from prod.BOM B
    where B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
	)
		BEGIN
        IF EXISTS (
				SELECT R.ID
        from prod.ROUTING R
        where R.[ORDER] = 1
            and R.ITEM_ID = @ITEM_ID
            and R.STEP_ID = @FROM_ID
			and R.factoryId = @factoryId
			) -- Tại công đoạn đầu tiên sẽ lấy theo định mức
				BEGIN
            INSERT INTO prod.MATERIALS_IN_PACKAGE
                (GUID,ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
            SELECT NEWID(), @ITEM_IN_PACKAGE_ID, B.MATERIALS_ID, (@QUANTITY-@TONCONLAI) * B.RATE
            FROM prod.BOM B
            WHERE B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
        END
			ELSE
				BEGIN
            INSERT INTO prod.[MATERIALS_IN_PACKAGE]
                ([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
            VALUES(NEWID(), @ITEM_IN_PACKAGE_ID, @MATERIALS_ID, @MATERIALS_QUANTITY)
        END
    END
	ELSE
		BEGIN
        INSERT INTO prod.[MATERIALS_IN_PACKAGE]
            ([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
        VALUES(NEWID(), @ITEM_IN_PACKAGE_ID, @MATERIALS_ID, @MATERIALS_QUANTITY)
    END
    END
	IF(@NEXT_ITEM_ID is not null)
	BEGIN
	IF(@NITEM_ID is not null)
	BEGIN
	
	update prod.PO
	set hanMucTon = hanMucTon - ROUND(@QUANTITY*@VOLUMN/@VOLUMN1,0) where number = @number and stepId = @FROM_ID and itemId = @NITEM_ID
	END
	IF(@NITEM_ID1 is not null)
	BEGIN
	
	update prod.PO
	set hanMucTon = hanMucTon - @QUANTITY*@VOLUMN/@VOLUMN2 where number = @number and (stepId = @NEXT_STEP_ID or stepId = @FROM_ID) and itemId = @NITEM_ID1
	END
	IF(@NITEM_ID3 is not null)
	BEGIN
	
	update prod.PO
	set hanMucTon = hanMucTon - ROUND(@QUANTITY*@VOLUMN/@VOLUMN3,0) where number = @number and stepId = @FROM_ID and itemId = @NITEM_ID3
	END
	END
--	IF(@TONCONLAI < @QUANTITY)
--	BEGIN
--	IF  @FROM_ID not in (select ID FROM [base].[DEPARTMENT] where TYPE2 = 'department') and EXISTS (
--		select ITEM_ID, SUM(quantity) as ton
--        from (
--                            select iip.ITEM_ID, sum(iip.QUANTITY) as quantity
--                from prod.ITEM_IN_PACKAGE iip
--                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
--                    left join prod.PO po on po.code = p.PO
--                where DESTINATION_ID = @FROM_ID and p.VERIFY_DATE is not null and p.TYPE_ID = 100026 
--				and p.PO in (select code from prod.PO where deletedAt is null and approvedAt is not null) 
--				--and (po.number = @LENHSX or @FROM_ID in (select ID from base.DEPARTMENT where NAME like N'%đóng gói%' and TYPE2 = 'department')) 
--				--and p.VERIFY_DATE is not null and p.TYPE_ID = 100026
--                group by iip.ITEM_ID

--            UNION ALL

--                select m.ITEM_ID, -sum(m.QUANTITY) as quantity
--                from prod.MATERIALS_IN_PACKAGE m
--                    left join prod.ITEM_IN_PACKAGE iip on m.ITEM_IN_PACKAGE_ID = iip.ID
--                    left join prod.PACKAGE p on iip.PACKAGE_ID = p.ID
--                    left join prod.PO po on po.code = p.PO
--                where SOURCE_ID = @FROM_ID and p.PO in (select code from prod.PO where deletedAt is null and approvedAt is not null) 
--				--and (po.number = @LENHSX or @FROM_ID in (select ID from base.DEPARTMENT where NAME like N'%đóng gói%' and TYPE2 = 'department'))
--                group by m.ITEM_ID
--		) as x
--        group by ITEM_ID
--        having SUM(quantity) < 0 and (ITEM_ID = @ITEM_ID or ITEM_ID in(
--	select B.MATERIALS_ID
--            from prod.BOM B
--            where B.ITEM_ID = @ITEM_ID 
--))
--	)
--	BEGIN
--        ROLLBACK
--        SET @ERROR = 4502
--        RETURN
--    END
--    END
	COMMIT

    -- Trả về thông tin package
	--update prod.PO set market = root where stepId in (100269,100272,100279) and status is null
	--update prod.PO set quantity = keHoach where quantity = 0
    SELECT
        P.ID id
    FROM prod.PACKAGE P
    WHERE P.[ID] = @PACKAGE_ID



    -- Trả về thông tin package
    SELECT
        P.ID packageId,
        P.SOURCE_ID fromId,
        P.DESTINATION_ID toId,
        P.CREATE_BY createBy,
        P.CREATE_DATE createDate
    FROM prod.PACKAGE P
    WHERE P.[ID] = @PACKAGE_ID
    -- Trả về thông tin item trong package
    SELECT
        P.ID packageId,
        IIP.ID itemInPackageId,
        IIP.ITEM_ID itemId,
        IIP.QUANTITY quantity
    FROM prod.PACKAGE P
        LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
    WHERE P.ID = @PACKAGE_ID
    -- Trả về nguyên liệu của pallet này
    SELECT
        IIP.ID itemInPackageId,
        MIP.ID materialsInPackageId,
        MIP.ITEM_ID itemId,
        MIP.QUANTITY quantity
    FROM prod.PACKAGE P
        LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
        LEFT JOIN prod.MATERIALS_IN_PACKAGE MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
    WHERE P.ID = @PACKAGE_ID

END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createPallet]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT

EXEC Proc_createPallet
999998,
200,
100000,
100001,
100000,
@ERROR = @E OUTPUT
*/

--SELECT * FROM prod.PALLET

CREATE   PROC [dbo].[Proc_createPallet] -- mộc máy, lắp ráp, đóng gói
@FROM_ID INT,
@TO_ID INT,
@ITEM_ID INT,
@QUANTITY MONEY,
@MATERIALS_ID INT,
@MATERIALS_QUANTITY INT,
@PLAN_ID INT,
@TYPE_ID INT,
@IKEA_CODE VARCHAR(100),
@IKEA_GUID VARCHAR(100),
@VENDOR_ID INT, -- Phụ
@WOOD_TYPE_ID INT,
@PRODUCTION_ORDERS_ID INT,
@CHEMISTRY_ID INT, -- Phụ
@PARCEL NVARCHAR(500), -- Phụ
@PROJECT_PRODUCT_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
SET XACT_ABORT ON
BEGIN TRANSACTION
	-- Tạo biến mã ballet
	DECLARE @PALLET_NUMBER INT
	-- Lấy ra mã ballet lớn nhất của tuần đó
	SELECT @PALLET_NUMBER = MAX([NUMBER])
	FROM prod.[PALLET]
	WHERE [YEAR] = YEAR(GETDATE())
	AND [WEEK] = DATEPART(WK,GETDATE())
	-- Nếu tuần đó chưa có mã ballet nào thì cho mã là 1, ko thì + 1
	IF @PALLET_NUMBER IS NULL
		BEGIN
			SET @PALLET_NUMBER = 1
		END
	ELSE
		BEGIN
			SET @PALLET_NUMBER = @PALLET_NUMBER + 1
		END
	DECLARE @PALLET_NUMBER_STRING VARCHAR(10)
	IF (@PALLET_NUMBER < 10)
	BEGIN
		SET @PALLET_NUMBER_STRING = CONCAT('000',@PALLET_NUMBER)
	END
	ELSE
	BEGIN
		IF (@PALLET_NUMBER < 100)
		BEGIN
			SET @PALLET_NUMBER_STRING = CONCAT('00',@PALLET_NUMBER)
		END
		ELSE
		BEGIN
			IF (@PALLET_NUMBER < 1000)
			BEGIN
				SET @PALLET_NUMBER_STRING = CONCAT('0',@PALLET_NUMBER)
			END
			ELSE
			BEGIN
				SET @PALLET_NUMBER_STRING = @PALLET_NUMBER
			END
		END
	END


		DECLARE @YEAR VARCHAR(20) = RIGHT(YEAR(GETDATE()),2)
		DECLARE @WEEK VARCHAR(20)
		IF DATEPART(WK,GETDATE()) < 10
		BEGIN
			SET @WEEK = CONCAT('0',DATEPART(WK,GETDATE()))
		END
		ELSE
		BEGIN
			SET @WEEK = DATEPART(WK,GETDATE())
		END
	--Chèn mã ballet
	DECLARE @PALLET_ID INT
	DECLARE @PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	INSERT INTO prod.[PALLET]([GUID],[CODE],[YEAR],[WEEK],[NUMBER],IKEA_CODE,IKEA_GUID,TYPE_ID,PROJECT_PRODUCT_ID,PARCEL,WOOD_TYPE_ID,PRODUCTION_ORDERS_ID,CREATE_BY,CREATE_DATE)
	VALUES (@PALLET_GUID,CONCAT(@YEAR,@WEEK,@PALLET_NUMBER_STRING),YEAR(GETDATE()),@WEEK,@PALLET_NUMBER,@IKEA_CODE,@IKEA_GUID,@TYPE_ID,@PROJECT_PRODUCT_ID,@PARCEL,@WOOD_TYPE_ID,@PRODUCTION_ORDERS_ID,@ACCOUNT_ID, GETDATE())
	
	SELECT @PALLET_ID = ID FROM prod.[PALLET] WHERE [GUID] = @PALLET_GUID
	-- chèn item in pallet
	INSERT INTO prod.[ITEM_IN_PALLET]
	VALUES (NEWID(),@PALLET_ID,@ITEM_ID,@QUANTITY)
	
	DECLARE @STEP_OF_PALLET_ID INT
	DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @PACKAGE_ID INT
	DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @ITEM_IN_PACKAGE_ID INT
	DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()

	INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,PASS,NOT_PASS,PLAN_ID,CREATE_BY,CREATE_DATE)
	VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,@ITEM_ID,@QUANTITY,0,@PLAN_ID,@ACCOUNT_ID, GETDATE())
	SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

	INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,[TYPE_ID],CREATE_BY,CREATE_DATE)
	VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@TYPE_ID,@ACCOUNT_ID,GETDATE())
	SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

	-- nếu tạo nội bộ trong kho thì sẽ xác nhận luôn
	IF (@FROM_ID = @TO_ID)
	BEGIN
		UPDATE prod.[PACKAGE]
		SET VERIFY_BY = @ACCOUNT_ID,VERIFY_DATE = GETDATE()
		WHERE ID = @PACKAGE_ID
	END

	INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
	VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@QUANTITY)
	SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID
	
	--INSERT INTO prod.[DEPENDENT]([GUID],STEP_OF_PALLET_ID,VENDOR_ID,CHEMISTRY_ID,PARCEL_ID)
	--VALUES (NEWID(),@STEP_OF_PALLET_ID,@VENDOR_ID,@CHEMISTRY_ID,@PARCEL_ID)

	-- Mức độ ưu tiên
	-- Kiểm tra xem có nguyên vật liệu gốc không
	-- Kiểm tra Bom
	-- Lấy chính sản phẩm xuất
	/*
	IF EXISTS (
				SELECT ID
				FROM prod.[BOM]
				WHERE ITEM_ID = @ITEM_ID)
				BEGIN -- nếu mà có bom cho sản phẩm xuất thì lấy theo bom
					INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
					SELECT NEWID(),@ITEM_IN_PACKAGE_ID,MATERIALS_ID,RATE*@QUANTITY
					FROM prod.BOM
					WHERE ITEM_ID = @ITEM_ID
				END
	ELSE
		BEGIN
			IF @MATERIALS_ID > 0
				BEGIN
					INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
					VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@MATERIALS_ID,@MATERIALS_QUANTITY)
				END
			ELSE
				BEGIN
					INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
					VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@QUANTITY)
				END

		END
		*/
			IF @MATERIALS_ID > 0
				BEGIN
					INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
					VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@MATERIALS_ID,@MATERIALS_QUANTITY)
				END
			ELSE
				BEGIN
					IF EXISTS (
								SELECT ID
								FROM prod.[BOM]
								WHERE ITEM_ID = @ITEM_ID
							)
						BEGIN -- nếu mà có bom cho sản phẩm xuất thì lấy theo bom
							INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
							SELECT NEWID(),@ITEM_IN_PACKAGE_ID,MATERIALS_ID,RATE*@QUANTITY
							FROM prod.BOM
							WHERE ITEM_ID = @ITEM_ID
						END
					ELSE
						BEGIN
							INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
							VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@QUANTITY)
						END
				END

	SELECT P.ID,
	P.CODE,
	@STEP_OF_PALLET_ID STEP_OF_PALLET_ID,
	P.CREATE_BY,
	P.CREATE_DATE
	FROM prod.[PALLET] P
	WHERE P.ID = @PALLET_ID

COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createPalletV2]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT

EXEC Proc_createPallet
999998,
200,
100000,
100001,
100000,
@ERROR = @E OUTPUT
*/

--SELECT * FROM prod.PALLET

CREATE   PROC [dbo].[Proc_createPalletV2]
@FROM_ID INT,
@TO_ID INT,
@ITEM NVARCHAR(MAX), --'100000-10,100001-20'
@ITEM_ID INT,
@QUANTITY MONEY,
@MATERIALS_ID INT,
@MATERIALS_QUANTITY INT,
@PLAN_ID INT,
@TYPE_ID INT,
@IKEA_CODE VARCHAR(100),
@IKEA_GUID VARCHAR(100),
@VENDOR_ID INT, -- Phụ
@WOOD_TYPE_ID INT,
@PRODUCTION_ORDERS_ID INT,
@CHEMISTRY_ID INT, -- Phụ
@PARCEL NVARCHAR(500), -- Phụ
@PROJECT_PRODUCT_ID INT,
@RECEIPT_ID INT,
@ACCOUNT_ID INT,
@factoryId INT,
@ERROR INT OUTPUT
AS
BEGIN
	SET XACT_ABORT ON
	BEGIN TRANSACTION
	update base.ACCOUNT set updatedAt = GETDATE() where id = @ACCOUNT_ID
	-----------------------------------Tạo mã pallet----------------------------------------
	-- Tạo biến mã ballet
	DECLARE @PALLET_NUMBER INT
	-- Lấy ra mã ballet lớn nhất của tuần đó
	SELECT @PALLET_NUMBER = MAX([NUMBER])
	FROM prod.[PALLET]
	WHERE [YEAR] = YEAR(GETDATE())
	AND [WEEK] = DATEPART(WK,GETDATE())
	-- Nếu tuần đó chưa có mã ballet nào thì cho mã là 1, ko thì + 1
	IF @PALLET_NUMBER IS NULL
		BEGIN
			SET @PALLET_NUMBER = 1
		END
	ELSE
		BEGIN
			SET @PALLET_NUMBER = @PALLET_NUMBER + 1
		END
	DECLARE @PALLET_NUMBER_STRING VARCHAR(10)
	IF (@PALLET_NUMBER < 10)
	BEGIN
		SET @PALLET_NUMBER_STRING = CONCAT('000',@PALLET_NUMBER)
	END
	ELSE
	BEGIN
		IF (@PALLET_NUMBER < 100)
		BEGIN
			SET @PALLET_NUMBER_STRING = CONCAT('00',@PALLET_NUMBER)
		END
		ELSE
		BEGIN
			IF (@PALLET_NUMBER < 1000)
			BEGIN
				SET @PALLET_NUMBER_STRING = CONCAT('0',@PALLET_NUMBER)
			END
			ELSE
			BEGIN
				SET @PALLET_NUMBER_STRING = @PALLET_NUMBER
			END
		END
	END

	DECLARE @YEAR VARCHAR(20) = RIGHT(YEAR(GETDATE()),2)
	DECLARE @WEEK VARCHAR(20)
	IF DATEPART(WK,GETDATE()) < 10
	BEGIN
		SET @WEEK = CONCAT('0',DATEPART(WK,GETDATE()))
	END
	ELSE
	BEGIN
		SET @WEEK = DATEPART(WK,GETDATE())
	END
	-----------------------------------Tạo mã pallet----------------------------------------
	DECLARE @PALLET_ID INT
	DECLARE @PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @STEP_OF_PALLET_ID INT
	DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @PACKAGE_ID INT
	DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()	
	DECLARE @ITEM_IN_PACKAGE_ID INT
	DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()

	--------------Kiểm tra mã Ikea--------------
	IF(@IKEA_GUID IS NOT NULL)
		BEGIN
			IF NOT EXISTS (
						SELECT ID FROM prod.PALLET WHERE IKEA_GUID = @IKEA_GUID
					)
				BEGIN
					DECLARE @LEN INT = LEN(@IKEA_CODE)
					DECLARE @INDEXOF19717 INT = CHARINDEX('19717',@IKEA_CODE)
					DECLARE @HEADER VARCHAR(100) = SUBSTRING(@IKEA_CODE, 1,3)
					DECLARE @MARKET VARCHAR(100) = SUBSTRING(@IKEA_CODE,4,@INDEXOF19717 - 4)
					DECLARE @ITEM_ID_TEMP INT

					SELECT @ITEM_ID_TEMP = PRODUCT_ID
					FROM base.[MARKET]
					WHERE [CODE] = @MARKET

					-- Kiểm tra các tham số
					IF (@LEN > 24 AND @LEN < 34 AND @INDEXOF19717 > 3 AND @HEADER = 240 AND @ITEM_ID_TEMP > 0 AND LEN(@IKEA_GUID) = 20 )
						BEGIN
							SET @ITEM_ID = @ITEM_ID_TEMP
							SET @QUANTITY = SUBSTRING(@IKEA_CODE, @INDEXOF19717 + 13, 6)
						END
					ELSE
						BEGIN
							ROLLBACK
							SET @ERROR = 4800
							RETURN
						END
				END
			ELSE
				BEGIN
					ROLLBACK
					SET @ERROR = 4801
					RETURN
				END
		END

	--------------Kiểm tra mã Ikea--------------
	-------------------Chèn mã và các thông tin chung của pallet----------------
	INSERT INTO prod.[PALLET]([GUID],[CODE],[YEAR],[WEEK],[NUMBER],IKEA_CODE,IKEA_GUID,[TYPE_ID],PROJECT_PRODUCT_ID,PARCEL,WOOD_TYPE_ID,PRODUCTION_ORDERS_ID,RECEIPT_ID,CREATE_BY,CREATE_DATE,factoryId)
	VALUES (@PALLET_GUID,CONCAT(@YEAR,@WEEK,@PALLET_NUMBER_STRING),YEAR(GETDATE()),@WEEK,@PALLET_NUMBER,@IKEA_CODE,@IKEA_GUID,@TYPE_ID,@PROJECT_PRODUCT_ID,@PARCEL,@WOOD_TYPE_ID,@PRODUCTION_ORDERS_ID,@RECEIPT_ID,@ACCOUNT_ID, GETDATE(),@factoryId)
	SELECT @PALLET_ID = ID FROM prod.[PALLET] WHERE [GUID] = @PALLET_GUID
	-- Tạo pallet thì ko cần ghi nhận pass với not pass
	INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,PLAN_ID,CREATE_BY,CREATE_DATE,factoryId)
	VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE(),@factoryId)
	SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID
	-- Tạo package
	INSERT INTO prod.[PACKAGE]([GUID],STEP_OF_PALLET_ID,SOURCE_ID,DESTINATION_ID,[TYPE_ID],CREATE_BY,CREATE_DATE,factoryId)
	VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@TYPE_ID,@ACCOUNT_ID,GETDATE(),@factoryId)
	SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

	-- nếu tạo nội bộ trong kho thì sẽ xác nhận luôn
	IF (@FROM_ID = @TO_ID)
	BEGIN
		UPDATE prod.[PACKAGE]
		SET VERIFY_BY = @ACCOUNT_ID,VERIFY_DATE = GETDATE()
		WHERE ID = @PACKAGE_ID
	END
	-------------------Chèn mã và các thông tin chung của pallet----------------
	
	-------------------chèn item in pallet----------------------------
	IF(@ITEM_ID > 0) -- Nếu có 1 item
		BEGIN
			-- chèn item in pallet
			INSERT INTO prod.[ITEM_IN_PALLET]([GUID],PALLET_ID,ITEM_ID,QUANTITY)
			VALUES (NEWID(),@PALLET_ID,@ITEM_ID,@QUANTITY)

			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@QUANTITY)
			SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID
			-- Mức độ ưu tiên
			-- Kiểm tra xem có nguyên vật liệu gốc không
			-- Kiểm tra Bom
			-- Lấy chính sản phẩm xuất

			IF @MATERIALS_ID > 0
				BEGIN
					INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
					VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@MATERIALS_ID,@MATERIALS_QUANTITY)
				END
			ELSE
				BEGIN
					IF EXISTS (
								SELECT ID
								FROM prod.[BOM]
								WHERE ITEM_ID = @ITEM_ID
							)
						BEGIN -- nếu mà có bom cho sản phẩm xuất thì lấy theo bom
							INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
							SELECT NEWID(),@ITEM_IN_PACKAGE_ID,MATERIALS_ID,RATE*@QUANTITY
							FROM prod.BOM
							WHERE ITEM_ID = @ITEM_ID
						END
					ELSE
						BEGIN
							INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
							VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@QUANTITY)
						END
				END
		END
	ELSE -- nếu có > 1 item
		BEGIN
			INSERT INTO prod.[ITEM_IN_PALLET]([GUID],PALLET_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(),@PALLET_ID,SUBSTRING([VALUE],1,6),SUBSTRING([VALUE],8,LEN([VALUE]))
			FROM STRING_SPLIT(@ITEM,',')
		
			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(),@PACKAGE_ID,SUBSTRING([VALUE],1,6),SUBSTRING([VALUE],8,LEN([VALUE]))
			FROM STRING_SPLIT(@ITEM,',')
			--tạo nhiều thì nguyên liệu cũng chính là thành phẩm.
			INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(), IIP.ID, IIP.ITEM_ID, IIP.QUANTITY
			FROM prod.[ITEM_IN_PACKAGE] IIP
			WHERE IIP.PACKAGE_ID = @PACKAGE_ID
		END

	COMMIT
	-- Trả về pallet
	SELECT 
	PL.ID id,
	PL.CODE code,
	@STEP_OF_PALLET_ID step_of_pallet_id,
	PL.CREATE_BY create_by,
	PL.CREATE_DATE create_date
	FROM prod.[PALLET] PL
	WHERE PL.ID = @PALLET_ID

	-- Trả về thông tin package
	SELECT 
	P.ID packageId,
	P.SOURCE_ID fromId,
	P.DESTINATION_ID toId,
	P.CREATE_BY createBy,
	P.CREATE_DATE createDate
	FROM prod.PALLET PL
	LEFT JOIN prod.STEP_OF_PALLET SOP ON SOP.PALLET_ID = PL.ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOP.ID
	WHERE PL.ID = @PALLET_ID
	-- Trả về thông tin item trong package
	SELECT 
	P.ID packageId,
	IIP.ID itemInPackageId,
	IIP.ITEM_ID itemId,
	IIP.QUANTITY quantity
	FROM prod.PALLET PL
	LEFT JOIN prod.STEP_OF_PALLET SOP ON SOP.PALLET_ID = PL.ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOP.ID
	LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
	WHERE PL.ID = @PALLET_ID
	-- Trả về nguyên liệu của pallet này
	SELECT 
	IIP.ID itemInPackageId,
	MIP.ID materialsInPackageId,
	MIP.ITEM_ID itemId,
	MIP.QUANTITY quantity
	FROM prod.PALLET PL
	LEFT JOIN prod.STEP_OF_PALLET SOP ON SOP.PALLET_ID = PL.ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOP.ID
	LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
	LEFT JOIN prod.MATERIALS_IN_PACKAGE MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
	WHERE PL.ID = @PALLET_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createpalletXepSay]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_createpalletXepSay]
@SOURCE_ID INT,
@DESTINATION_ID INT,
@ITEM VARCHAR(MAX), --'100000-10,100000-20'
@PLAN_ID INT,
@PARCEL NVARCHAR(500),
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	SET XACT_ABORT ON
    BEGIN TRANSACTION
		update base.ACCOUNT set updatedAt = GETDATE() where id = @ACCOUNT_ID
    		-- Tạo biến mã ballet
		DECLARE @PALLET_NUMBER INT
		-- Lấy ra mã ballet lớn nhất của tuần đó
		SELECT @PALLET_NUMBER = MAX([NUMBER])
		FROM prod.[PALLET]
		WHERE [YEAR] = YEAR(GETDATE())
		AND [WEEK] = DATEPART(WK,GETDATE())
		-- Nếu tuần đó chưa có mã ballet nào thì cho mã là 1, ko thì + 1
		IF @PALLET_NUMBER IS NULL
			BEGIN
				SET @PALLET_NUMBER = 1
			END
		ELSE
			BEGIN
				SET @PALLET_NUMBER = @PALLET_NUMBER + 1
			END
			DECLARE @PALLET_NUMBER_STRING VARCHAR(10)
	IF (@PALLET_NUMBER < 10)
	BEGIN
		SET @PALLET_NUMBER_STRING = CONCAT('000',@PALLET_NUMBER)
	END
	ELSE
	BEGIN
		IF (@PALLET_NUMBER < 100)
		BEGIN
			SET @PALLET_NUMBER_STRING = CONCAT('00',@PALLET_NUMBER)
		END
		ELSE
		BEGIN
			IF (@PALLET_NUMBER < 1000)
			BEGIN
				SET @PALLET_NUMBER_STRING = CONCAT('0',@PALLET_NUMBER)
			END
			ELSE
			BEGIN
				SET @PALLET_NUMBER_STRING = @PALLET_NUMBER
			END
		END
	END
		DECLARE @YEAR VARCHAR(20) = RIGHT(YEAR(GETDATE()),2)
		DECLARE @WEEK VARCHAR(20)
		IF DATEPART(WK,GETDATE()) < 10
		BEGIN
			SET @WEEK = CONCAT('0',DATEPART(WK,GETDATE()))
		END
		ELSE
		BEGIN
			SET @WEEK = DATEPART(WK,GETDATE())
		END
		--Chèn mã ballet
		DECLARE @PALLET_ID INT
		DECLARE @PALLET_GUID UNIQUEIDENTIFIER = NEWID()
		INSERT INTO prod.[PALLET]([GUID],[CODE],[YEAR],[WEEK],[NUMBER],[PARCEL],CREATE_BY,CREATE_DATE)
		VALUES (@PALLET_GUID,CONCAT(@YEAR,@WEEK,@PALLET_NUMBER_STRING),YEAR(GETDATE()),@WEEK,@PALLET_NUMBER,@PARCEL,@ACCOUNT_ID, GETDATE())
		SELECT @PALLET_ID = ID FROM prod.[PALLET] WHERE [GUID] = @PALLET_GUID
		
		-- chèn item trong pallet
        INSERT INTO prod.[ITEM_IN_PALLET]([GUID],PALLET_ID,ITEM_ID,QUANTITY)
		SELECT NEWID(),@PALLET_ID,SUBSTRING([VALUE],1,6),SUBSTRING([VALUE],8,LEN([VALUE]))
		FROM STRING_SPLIT(@ITEM,',')

		DECLARE @STEP_OF_PALLET_ID INT
		DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
		DECLARE @PACKAGE_ID INT
		DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
		
		INSERT INTO prod.[STEP_OF_PALLET]([GUID],[PALLET_ID],[STEP_ID],[STEP_NEXT_ID],PLAN_ID,CREATE_BY,CREATE_DATE)
		VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@SOURCE_ID,@DESTINATION_ID,@PLAN_ID,@ACCOUNT_ID,GETDATE())
		SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

		INSERT INTO prod.[PACKAGE]([GUID],STEP_OF_PALLET_ID,SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
		VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@SOURCE_ID,@DESTINATION_ID,@ACCOUNT_ID,GETDATE())
		SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

		INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
		SELECT NEWID(),@PACKAGE_ID,SUBSTRING([VALUE],1,6),SUBSTRING([VALUE],8,LEN([VALUE]))
		FROM STRING_SPLIT(@ITEM,',')

		INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
		SELECT NEWID(),IIP.ID,IIP.ITEM_ID,IIP.QUANTITY
		FROM prod.[ITEM_IN_PACKAGE] IIP
		LEFT JOIN prod.[MATERIALS_IN_PACKAGE] MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
		WHERE MIP.ID IS NULL


        SELECT P.ID,
		P.CODE,
		P.CREATE_BY,
		P.CREATE_DATE
		FROM prod.[PALLET] P
		WHERE P.ID = @PALLET_ID 

    COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createRequire]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_createRequire]
@PALLET_CODE VARCHAR(20),
@STEP_ID INT,
@ITEM_ID INT,
@QUANTITY MONEY,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT

AS
BEGIN

SET XACT_ABORT ON
BEGIN TRANSACTION
    DECLARE @PALLET_ID INT
    DECLARE @PALLET_GUID UNIQUEIDENTIFIER = NEWID()

    SELECT @PALLET_ID = ID 
    FROM dbo.[PALLET]
    WHERE CODE = @PALLET_CODE


    INSERT INTO dbo.[REQUIRE]([GUID],PALLET_ID,STEP_ID,ITEM_ID,QUANTITY,CREATE_BY,CREATE_DATE)
    VALUES (@PALLET_GUID,@PALLET_ID,@STEP_ID,@ITEM_ID,@QUANTITY,@ACCOUNT_ID,GETDATE())
COMMIT

SELECT ID
FROM dbo.[REQUIRE]
WHERE [GUID] = @PALLET_GUID



END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createRouting]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_createRouting]
@ITEM_ID INT,
@STEP_ID INT,
@ORDER INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN

IF NOT EXISTS (
	SELECT ID FROM dbo.[ROUTING]
	WHERE ITEM_ID = @ITEM_ID
	AND [ORDER] = @ORDER 
)
	BEGIN -- Kiểm tra số order của item đó không được trùng nhau
		IF EXISTS (SELECT ID FROM dbo.[ROUTING]
			WHERE ITEM_ID = @ITEM_ID
			AND STEP_ID = @STEP_ID
		)
			BEGIN -- đã tồn tại thì update order
				UPDATE dbo.[ROUTING]
				SET [ORDER] = @ORDER, MODIFY_BY = @ACCOUNT_ID ,MODIFY_DATE = GETDATE()
				WHERE ITEM_ID = @ITEM_ID
				AND STEP_ID = @STEP_ID
			END
		ELSE
			BEGIN
				INSERT INTO dbo.[ROUTING]([GUID],ITEM_ID,STEP_ID,[ORDER],CREATE_BY,CREATE_DATE)
				VALUES (NEWID(),@ITEM_ID,@STEP_ID , @ORDER,@ACCOUNT_ID,GETDATE())
			END
	END
SELECT ID
FROM dbo.[ROUTING]
WHERE ITEM_ID = @ITEM_ID
AND STEP_ID = @STEP_ID

END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createStepOfPallet]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT
EXEC Proc_createStepOfPallet
'19322',
100001,
100002,
20,
0,
100000,
100000,
@ERROR = @E

*/
/*
EXEC Proc_createStepOfPallet
'100000',
100001,
100002,
100001
*/

CREATE   PROC [dbo].[Proc_createStepOfPallet] -- dùng sau khi lựa phôi
@PALLET_CODE VARCHAR(20),
@FROM_ID INT,
@TO_ID INT,
@KILN_BATCH_ID INT,
@PASS MONEY,
@NOT_PASS MONEY,
@PLAN_ID INT,
@VENDOR_ID INT,
@CHEMISTRY_ID INT,
@PARCEL_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
SET XACT_ABORT ON
BEGIN TRANSACTION
	DECLARE @PALLET_ID INT
	-- Kiểm tra xem pallet có đang trong kho đó không
	IF NOT EXISTS (
		SELECT A.STEP
		FROM (
		SELECT TOP(1) SOP.ID,SOP.STEP_NEXT_ID STEP
		FROM prod.[STEP_OF_PALLET] SOP
		LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
		LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
		WHERE PL.CODE = @PALLET_CODE
		ORDER BY SOP.ID DESC
		) A
		LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = A.ID
		WHERE P.VERIFY_BY IS NOT NULL
		AND A.STEP = @FROM_ID
	)BEGIN
		ROLLBACK
		SET @ERROR = 4505
		RETURN
	END

	SELECT @PALLET_ID = ID 
	FROM prod.[PALLET] 
	WHERE [CODE] = @PALLET_CODE
	
	DECLARE @STEP_OF_PALLET_ID INT
	DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @PACKAGE_ID INT
	DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @ITEM_IN_PACKAGE_ID INT
	DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
	
	DECLARE @ITEM_COUNT INT

	SELECT @ITEM_COUNT = COUNT(ID)
	FROM prod.[ITEM_IN_PALLET]
	WHERE [PALLET_ID] = @PALLET_ID

	IF @ITEM_COUNT > 1
		BEGIN
			INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,PASS,NOT_PASS,KILN_BATCH_ID,PLAN_ID,CREATE_BY,CREATE_DATE)
			VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,NULL,NULL,NULL,@KILN_BATCH_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE())
			SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

			INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
			VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@ACCOUNT_ID,GETDATE())
			SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(),@PACKAGE_ID,ITEM_ID,QUANTITY
			FROM prod.[ITEM_IN_PALLET]
			WHERE PALLET_ID = @PALLET_ID

			INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
			SELECT NEWID(),IIP.ID,IIP.ITEM_ID,IIP.QUANTITY 
			FROM prod.[ITEM_IN_PACKAGE] IIP
			LEFT JOIN prod.[MATERIALS_IN_PACKAGE] MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
			WHERE MIP.ID IS NULL
		END
	ELSE
		BEGIN
			DECLARE @ITEM_ID INT
			SELECT @ITEM_ID = ITEM_ID FROM prod.[ITEM_IN_PALLET] WHERE [PALLET_ID] = @PALLET_ID

			--Lấy tồn
			DECLARE @INVENTORY MONEY
			SELECT TOP(1) @INVENTORY = PASS
            FROM prod.[STEP_OF_PALLET]
            WHERE PALLET_ID = @PALLET_ID
			ORDER BY ID DESC

			SET @NOT_PASS = @INVENTORY - @PASS

			INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,PASS,NOT_PASS,KILN_BATCH_ID,PLAN_ID,CREATE_BY,CREATE_DATE)
			VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,@ITEM_ID,@PASS,@NOT_PASS,@KILN_BATCH_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE())
			SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

			INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
			VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@ACCOUNT_ID,GETDATE())
			SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

			IF(@KILN_BATCH_ID IS NOT NULL)
				BEGIN
					SELECT @ITEM_ID = IIP.ITEM_ID, @PASS = IIP.QUANTITY
					FROM prod.ITEM_IN_PALLET IIP
					WHERE IIP.PALLET_ID = @PALLET_ID
				END

			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@PASS)
			SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

			INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
			VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@PASS)
			
			INSERT INTO prod.[DEPENDENT]([GUID],STEP_OF_PALLET_ID,VENDOR_ID,CHEMISTRY_ID,PARCEL_ID)
			VALUES (NEWID(),@STEP_OF_PALLET_ID,@VENDOR_ID,@CHEMISTRY_ID,@PARCEL_ID)
			
			
			IF (@NOT_PASS > 0) --  Đang mặc định xuất sang QC thuận Hưng 100025
			BEGIN
				DECLARE @ERROR_HANDLING INT

				SELECT @ERROR_HANDLING = [ERROR]
				FROM base.DEPARTMENT
				WHERE ID = @FROM_ID
				
				IF @ERROR_HANDLING IS NULL
				BEGIN
					ROLLBACK
					SET @ERROR = 4540
					RETURN
				END

				INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
				VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@ERROR_HANDLING,@ACCOUNT_ID,GETDATE())
				SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

				INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
				VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@NOT_PASS)
				SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

				INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
				VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@NOT_PASS)
			END

		END
COMMIT	
	SELECT ID
	FROM prod.[STEP_OF_PALLET]
	WHERE ID = @STEP_OF_PALLET_ID

END
GO
/****** Object:  StoredProcedure [dbo].[Proc_createStepOfPalletXepSay]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_createStepOfPalletXepSay] -- dùng khi ở sấy
@PALLET_CODE VARCHAR(20),
@FROM_ID INT,
@TO_ID INT,
@KILN_BATCH_ID INT,
@PLAN_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	DECLARE @PALLET_ID INT

	--DECLARE @YEAR VARCHAR(10) = CONCAT('20',SUBSTRING(@PALLET_CODE,1,2))
	--DECLARE @WEEK VARCHAR(10) = SUBSTRING(@PALLET_CODE,3,2)
	--DECLARE @NUMBER INT = CONVERT(INT,SUBSTRING(@PALLET_CODE,5,LEN(@PALLET_CODE)-4)) 
	
	IF NOT EXISTS (
		SELECT ID
		FROM dbo.[PALLET]
		WHERE [CODE] = @PALLET_CODE
	)BEGIN
		SET @ERROR = 430
		RETURN 
	END

	SELECT @PALLET_ID = ID 
	FROM dbo.[PALLET] 
	WHERE [CODE] = @PALLET_CODE

	DECLARE @STEP_OF_PALLET_ID INT
	DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @PACKAGE_ID INT
	DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()


			INSERT INTO dbo.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,PASS,NOT_PASS,KILN_BATCH_ID,PLAN_ID,CREATE_BY,CREATE_DATE)
			VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,NULL,NULL,NULL,@KILN_BATCH_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE())
			SELECT @STEP_OF_PALLET_ID = ID FROM dbo.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

			INSERT INTO dbo.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
			VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@ACCOUNT_ID,GETDATE())
			SELECT @PACKAGE_ID = ID FROM dbo.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

			INSERT INTO dbo.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(),@PACKAGE_ID,ITEM_ID,QUANTITY
			FROM dbo.[ITEM_IN_PALLET]
			WHERE PALLET_ID = @PALLET_ID

			INSERT INTO dbo.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
			SELECT NEWID(),IIP.ID,IIP.ITEM_ID,IIP.QUANTITY 
			FROM dbo.[ITEM_IN_PACKAGE] IIP
			LEFT JOIN dbo.[MATERIALS_IN_PACKAGE] MIP ON MIP.ITEM_IN_PACKAGE_ID = IIP.ID
			WHERE MIP.ID IS NULL

				SELECT ID
	FROM dbo.[STEP_OF_PALLET]
	WHERE ID = @STEP_OF_PALLET_ID

END
GO
/****** Object:  StoredProcedure [dbo].[Proc_exportKilnBatch]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT
EXEC Proc_exportKilnBatch
100003,
100000,
@ERROR = @E OUTPUT
PRINT @E
*/


CREATE   PROC [dbo].[Proc_exportKilnBatch]
@KILN_BATCH_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	IF NOT EXISTS ( -- kiểm tra xem mẻ đó có ko và đã ra lò chưa và qc đã xác nhận
		SELECT ID
		FROM prod.[KILN_BATCH]
		WHERE ID = @KILN_BATCH_ID
	AND TIME_OUT_REAL IS NULL
	AND VERIFY IS NOT NULL
	)
	BEGIN
		SET @ERROR = 4700
		RETURN
	END

SET XACT_ABORT ON
BEGIN TRANSACTION 
	
	INSERT INTO prod.STEP_OF_PALLET ([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,CREATE_BY,CREATE_DATE)
	SELECT NEWID(),SOP.PALLET_ID,K.STEP_ID,KB.STEP_NEXT_ID,ITEM_ID,@ACCOUNT_ID,GETDATE()
	FROM prod.[STEP_OF_PALLET] SOP
	LEFT JOIN prod.KILN_BATCH KB ON KB.ID = SOP.KILN_BATCH_ID
	LEFT JOIN prod.KILN K ON K.ID = KB.KILN_ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID

	INSERT INTO prod.PACKAGE (GUID,STEP_OF_PALLET_ID,SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE,VERIFY_BY,VERIFY_DATE)
	SELECT NEWID(),SOPOUT.ID,SOPOUT.STEP_ID,SOPOUT.STEP_NEXT_ID,@ACCOUNT_ID,GETDATE(),@ACCOUNT_ID,GETDATE()
	FROM prod.STEP_OF_PALLET SOP
	LEFT JOIN prod.STEP_OF_PALLET SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID
	GROUP BY SOPOUT.ID,SOPOUT.STEP_ID,SOPOUT.STEP_NEXT_ID

	INSERT INTO prod.ITEM_IN_PACKAGE([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
	SELECT NEWID(),P.ID,IIP.ITEM_ID,IIP.QUANTITY
	FROM prod.STEP_OF_PALLET SOP
	LEFT JOIN prod.STEP_OF_PALLET SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOPOUT.ID
	LEFT JOIN prod.ITEM_IN_PALLET IIP ON IIP.PALLET_ID = SOPOUT.PALLET_ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID
	GROUP BY SOPOUT.ID,P.ID,IIP.ITEM_ID,IIP.QUANTITY

	INSERT INTO prod.MATERIALS_IN_PACKAGE([GUID],ITEM_IN_PACKAGE_ID,ITEM_ID,QUANTITY)
	SELECT NEWID(),IIP.ID,IIP.ITEM_ID,IIP.QUANTITY
	FROM prod.STEP_OF_PALLET SOP
	LEFT JOIN prod.STEP_OF_PALLET SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOPOUT.ID
	LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID
	GROUP BY SOPOUT.ID,IIP.ID,IIP.ITEM_ID,IIP.QUANTITY

	UPDATE prod.[KILN_BATCH]
	SET TIME_OUT_REAL = DATEDIFF(DAY, [CREATE_DATE], GETDATE()),
	EXPORT_BY = @ACCOUNT_ID,
	EXPORT_DATE = GETDATE(),
	[STATUS] = 'finish'
	WHERE ID = @KILN_BATCH_ID
COMMIT
	-- Trả về id mẻ sấy
	SELECT ID
	FROM prod.[KILN_BATCH]
	WHERE ID = @KILN_BATCH_ID
	-- Trả về thông tin package
	SELECT
	P.ID packageId,
	P.SOURCE_ID fromId,
	P.DESTINATION_ID toId,
	P.CREATE_BY createBy,
	P.CREATE_DATE createDate
	FROM prod.STEP_OF_PALLET SOP
	LEFT JOIN prod.STEP_OF_PALLET SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOPOUT.ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID
	-- Trả về thông tin item trong package
	SELECT 
	P.ID packageId,
	IIP.ID itemInPackageId,
	IIP.ITEM_ID itemId,
	IIP.QUANTITY quantity
	FROM prod.STEP_OF_PALLET SOP
	LEFT JOIN prod.STEP_OF_PALLET SOPOUT ON SOPOUT.PALLET_ID = SOP.PALLET_ID AND SOPOUT.STEP_ID = SOP.STEP_NEXT_ID
	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOPOUT.ID
	LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
	WHERE SOP.KILN_BATCH_ID = @KILN_BATCH_ID

	-- Không cần trả về nguyên liệu vì sẽ bằng chính thành phẩm
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_GetNguyenLieuByPO]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Proc_GetNguyenLieuByPO]
    @code char(36)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    declare @LENHSX nvarchar(100), @FROM_ID int, @ITEM_ID int, @NGUONPHOI int,@factoryId INT
    select @LENHSX = number, @FROM_ID = stepId, @ITEM_ID = itemId, @factoryId = factoryId
    from prod.PO
    where code = @code
    select *
    from (
                select ITEM_ID,CASE
				WHEN SUM(quantity)< 0 then 0
				ELSE SUM(quantity)
				END as ton
        from (
                                             select ITEM_ID, -QUANTITY as QUANTITY
                from prod.MATERIALS_IN_PACKAGE
                where ITEM_IN_PACKAGE_ID in (
                  select ID
                    from prod.ITEM_IN_PACKAGE
                    where PACKAGE_ID in (
                    select ID
                    from prod.PACKAGE
                    where PO is not null and PO in (select code
                        from prod.PO
                        where deletedAt is null and approvedAt is not null and endPo = 0
                                        ) and SOURCE_ID = @FROM_ID
                  )
                ) and (ITEM_ID = @ITEM_ID or ITEM_ID in(
                  select B.MATERIALS_ID
                    from prod.BOM B
                    where B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
                ))

            union all
                select ITEM_ID, QUANTITY
                from prod.ITEM_IN_PACKAGE
                where PACKAGE_ID in (
                    select ID
                    from prod.PACKAGE
                    where PO is not null and PO in (select code
                        from prod.PO
                        where deletedAt is null and approvedAt is not null and endPo = 0
                                        ) and DESTINATION_ID = @FROM_ID and TYPE_ID = 100026 and VERIFY_DATE is not null
                  ) and (ITEM_ID = @ITEM_ID or ITEM_ID in(
                  select B.MATERIALS_ID
                    from prod.BOM B
                    where B.ITEM_ID = @ITEM_ID and B.factoryId = @factoryId
                ))) as x
        group by ITEM_ID
                ) as NL left join base.ITEM I on I.ID = NL.ITEM_ID
--where ton >= 0
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_getPlanId]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_getPlanId]
@YEAR INT,
@WEEK INT,
@STEP_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN

	IF NOT EXISTS (SELECT ID FROM dbo.[PLAN]
	WHERE [YEAR] = @YEAR
		AND	[WEEK] = @WEEK
		AND [STEP_ID] = @STEP_ID
	)
	BEGIN
		INSERT INTO dbo.[PLAN]([GUID],CODE,[YEAR],[WEEK],STEP_ID,CREATE_BY,CREATE_DATE)
		VALUES (NEWID(),CONCAT(@YEAR,@WEEK),@YEAR,@WEEK,@STEP_ID,@ACCOUNT_ID,GETDATE())
	END

	SELECT ID FROM dbo.[PLAN]
	WHERE [YEAR] = @YEAR
		AND	[WEEK] = @WEEK
		AND [STEP_ID] = @STEP_ID

END
GO
/****** Object:  StoredProcedure [dbo].[Proc_getStepNextId]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
DECLARE @RC int
DECLARE @PALLET_ID int

-- TODO: Set parameter values here.

EXECUTE [prod].[Proc_getStepNextId] 
   @PALLET_ID = 100128
GO

*/

CREATE   PROC [dbo].[Proc_getStepNextId]
@PALLET_ID INT
AS
BEGIN

DECLARE @STEP_NOW INT
DECLARE @ORDER INT

SELECT TOP(1) @STEP_NOW = SOP.STEP_NEXT_ID
FROM prod.[STEP_OF_PALLET] SOP
WHERE SOP.PALLET_ID = @PALLET_ID
ORDER BY ID DESC


SELECT @ORDER = R.[ORDER]
FROM prod.[ITEM_IN_PALLET] IIP
LEFT JOIN prod.[ROUTING] R ON R.ITEM_ID = IIP.ITEM_ID
WHERE IIP.PALLET_ID = @PALLET_ID
AND R.STEP_ID = @STEP_NOW

IF @ORDER IS NULL
BEGIN
    SET @ORDER = 0
END

SET @ORDER = @ORDER + 1

IF EXISTS ( SELECT R.STEP_ID
            FROM prod.[ITEM_IN_PALLET] IIP
            LEFT JOIN prod.[ROUTING] R ON R.ITEM_ID = IIP.ITEM_ID
            WHERE IIP.PALLET_ID = @PALLET_ID
            AND R.[ORDER] = @ORDER
        )
    BEGIN
        SELECT R.STEP_ID
        FROM prod.[ITEM_IN_PALLET] IIP
        LEFT JOIN prod.[ROUTING] R ON R.ITEM_ID = IIP.ITEM_ID
        WHERE IIP.PALLET_ID = @PALLET_ID
        AND R.[ORDER] = @ORDER
    END
ELSE
    BEGIN
        SELECT RN.DEPARTMENT_ID STEP_ID
        FROM prod.PALLET PL
        LEFT JOIN prod.PRODUCTION_ORDERS PO ON PO.ID = PL.PRODUCTION_ORDERS_ID
        LEFT JOIN prod.STEP_OF_PALLET SOP ON SOP.PALLET_ID = PL.ID
        LEFT JOIN prod.ROUTINGS RC ON RC.NAME = PO.ROUTING_NAME AND RC.DEPARTMENT_ID = SOP.STEP_NEXT_ID
        LEFT JOIN prod.ROUTINGS RN ON RN.NAME = RC.NAME AND RN.[ORDER] = RC.[ORDER] + 1
        WHERE PL.ID = @PALLET_ID
        ORDER BY SOP.ID DESC
    END
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_KHverifyPackage]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_KHverifyPackage]
@PACKAGE_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	
	IF NOT EXISTS (
		SELECT *
		FROM dbo.[PACKAGE]
		WHERE ID = @PACKAGE_ID
	)
	BEGIN
		SET @ERROR = 430
		RETURN
	END
	
	UPDATE dbo.[PACKAGE]
	SET KH_VERIFY_BY = @ACCOUNT_ID,KH_VERIFY_DATE = GETDATE()
	WHERE ID = @PACKAGE_ID


	SELECT ID FROM dbo.[PACKAGE]
	WHERE ID = @PACKAGE_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_movePallet]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @E INT
EXEC Proc_createStepOfPallet
'19322',
100001,
100002,
20,
0,
100000,
100000,
@ERROR = @E

*/
/*
EXEC Proc_createStepOfPallet
'100000',
100001,
100002,
100001
*/

CREATE   PROC [dbo].[Proc_movePallet] -- dùng sau khi lựa phôi
@PALLET_CODE VARCHAR(20),
@FROM_ID INT,
@TO_ID INT,
@KILN_BATCH_ID INT,
@PASS MONEY,
@IKEA_GUID VARCHAR(100),
@PLAN_ID INT,
@VENDOR_ID INT,
@CHEMISTRY_ID INT,
@PARCEL_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
-- -- kiểm tra mã ikeaGuid
-- IF(@IKEA_GUID IS NOT NULL)
--	BEGIN
--		IF EXISTS (	SELECT PL.ID
--					FROM prod.PALLET PL
--					WHERE PL.IKEA_GUID = @IKEA_GUID
--					)
--			BEGIN
--				SELECT @PALLET_CODE = PL.CODE, @PASS = IIP.QUANTITY
--				FROM prod.PALLET PL
--				LEFT JOIN prod.ITEM_IN_PALLET IIP ON IIP.PALLET_ID = PL.ID
--				WHERE PL.IKEA_GUID = @IKEA_GUID
--			END
--		ELSE
--			BEGIN
--				SET @ERROR = 430
--				RETURN
--			END
--	END
--SET XACT_ABORT ON
BEGIN TRANSACTION
	DECLARE @PALLET_ID INT
	-- Xác nhận trước khi vò lò
	update prod.PACKAGE set VERIFY_BY = @ACCOUNT_ID, VERIFY_DATE = GETDATE() where STEP_OF_PALLET_ID in (
	SELECT A.ID
		FROM (
		SELECT TOP(1) SOP.ID,SOP.STEP_NEXT_ID STEP
		FROM prod.[STEP_OF_PALLET] SOP
		LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
		LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
		WHERE PL.CODE = @PALLET_CODE
		ORDER BY SOP.ID DESC
		) A
		--WHERE A.STEP = @FROM_ID
	)
	-- Kiểm tra xem pallet có đang trong kho đó không
	--IF  EXISTS (
	--	SELECT A.STEP
	--	FROM (
	--	SELECT TOP(1) SOP.ID,SOP.STEP_NEXT_ID STEP
	--	FROM prod.[STEP_OF_PALLET] SOP
	--	LEFT JOIN prod.[PACKAGE] P ON P.STEP_OF_PALLET_ID = SOP.ID AND P.DESTINATION_ID = SOP.STEP_NEXT_ID
	--	LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
	--	WHERE PL.CODE = @PALLET_CODE
	--	ORDER BY SOP.ID DESC
	--	) A
	--	LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = A.ID
	--	WHERE P.VERIFY_BY IS NOT NULL
	--	AND A.STEP = @FROM_ID
	--)BEGIN
	--	ROLLBACK
	--	SET @ERROR = 4505
	--	RETURN
	--END

	SELECT @PALLET_ID = ID 
	FROM prod.[PALLET] 
	WHERE [CODE] = @PALLET_CODE

	DECLARE @STEP_OF_PALLET_ID INT
	DECLARE @STEP_OF_PALLET_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @PACKAGE_ID INT
	DECLARE @PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
	DECLARE @ITEM_IN_PACKAGE_ID INT
	DECLARE @ITEM_IN_PACKAGE_GUID UNIQUEIDENTIFIER = NEWID()
	
	DECLARE @ITEM_COUNT INT

	SELECT @ITEM_COUNT = COUNT(ID)
	FROM prod.[ITEM_IN_PALLET]
	WHERE [PALLET_ID] = @PALLET_ID

	IF @ITEM_COUNT > 1 -- Chỉ là các pallet đạt 100%
		BEGIN
			INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,KILN_BATCH_ID,PLAN_ID,CREATE_BY,CREATE_DATE)
			VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,@KILN_BATCH_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE())
			SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

			INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
			VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@ACCOUNT_ID,GETDATE())
			SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			SELECT NEWID(),@PACKAGE_ID,ITEM_ID,QUANTITY
			FROM prod.[ITEM_IN_PALLET]
			WHERE PALLET_ID = @PALLET_ID

			INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
			SELECT NEWID(),IIP.ID,IIP.ITEM_ID,IIP.QUANTITY 
			FROM prod.[ITEM_IN_PACKAGE] IIP
            WHERE IIP.PACKAGE_ID = @PACKAGE_ID
		END
	ELSE
		BEGIN
			DECLARE @ITEM_ID INT
			SELECT @ITEM_ID = ITEM_ID FROM prod.[ITEM_IN_PALLET] WHERE [PALLET_ID] = @PALLET_ID

			--Lấy tồn
			DECLARE @INVENTORY MONEY
            -- Lấy lần pass cuối cùng
			SELECT TOP(1) @INVENTORY = PASS
            FROM prod.[STEP_OF_PALLET]
            WHERE PALLET_ID = @PALLET_ID
			ORDER BY ID DESC
            -- Nếu chưa có lần pass nào thì sẽ thấy số lượng đầu tiên.
            IF(@INVENTORY IS NULL)
                BEGIN
                    SELECT @INVENTORY = [QUANTITY]
                    FROM prod.ITEM_IN_PALLET IIP
                    WHERE IIP.PALLET_ID = @PALLET_ID
					-- Nếu chưa có lần pass nào mà cũng ko có thông tin pass thì lấy số lượng đầu tiên
					IF (@PASS IS NULL)
						BEGIN
							SELECT @PASS = [QUANTITY]
							FROM prod.ITEM_IN_PALLET IIP
							WHERE IIP.PALLET_ID = @PALLET_ID
						END
                END
			ELSE
				BEGIN
					-- Nếu đã có lần pass mà lại ko có thông tin pass thì lấy lần pass cuối cùng
					IF(@PASS IS NULL)
						BEGIN
							SET @PASS = @INVENTORY
						END
				END

			DECLARE @NOT_PASS MONEY = (@INVENTORY - @PASS)

            IF(@NOT_PASS < 0) -- còn 200 không thể pass 300 được
            BEGIN
                ROLLBACK
                SET @ERROR = 4502
                RETURN
            END

			INSERT INTO prod.[STEP_OF_PALLET]([GUID],PALLET_ID,STEP_ID,STEP_NEXT_ID,ITEM_ID,PASS,NOT_PASS,KILN_BATCH_ID,PLAN_ID,CREATE_BY,CREATE_DATE)
			VALUES(@STEP_OF_PALLET_GUID,@PALLET_ID,@FROM_ID,@TO_ID,@ITEM_ID,@PASS,@NOT_PASS,@KILN_BATCH_ID,@PLAN_ID,@ACCOUNT_ID, GETDATE())
			SELECT @STEP_OF_PALLET_ID = ID FROM prod.[STEP_OF_PALLET] WHERE [GUID] = @STEP_OF_PALLET_GUID

			INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
			VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@TO_ID,@ACCOUNT_ID,GETDATE())
			SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

			INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
			VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@PASS)
			SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

			INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
			VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@PASS)
			
			IF (@NOT_PASS > 0) --  
			BEGIN
				DECLARE @ERROR_HANDLING INT
                -- Lấy nơi xuất hàng lỗi của bộ phận này.
				SELECT @ERROR_HANDLING = [ERROR]
				FROM base.DEPARTMENT
				WHERE ID = @FROM_ID
				
				IF @ERROR_HANDLING IS NULL
				BEGIN
					ROLLBACK
					SET @ERROR = 4540
					RETURN
				END

				INSERT INTO prod.[PACKAGE]([GUID],[STEP_OF_PALLET_ID],SOURCE_ID,DESTINATION_ID,CREATE_BY,CREATE_DATE)
				VALUES(@PACKAGE_GUID,@STEP_OF_PALLET_ID,@FROM_ID,@ERROR_HANDLING,@ACCOUNT_ID,GETDATE())
				SELECT @PACKAGE_ID = ID FROM prod.[PACKAGE] WHERE [GUID] = @PACKAGE_GUID

				INSERT INTO prod.[ITEM_IN_PACKAGE]([GUID],PACKAGE_ID,ITEM_ID,QUANTITY)
				VALUES (@ITEM_IN_PACKAGE_GUID,@PACKAGE_ID,@ITEM_ID,@NOT_PASS)
				SELECT @ITEM_IN_PACKAGE_ID = ID FROM prod.[ITEM_IN_PACKAGE] WHERE [GUID] = @ITEM_IN_PACKAGE_GUID

				INSERT INTO prod.[MATERIALS_IN_PACKAGE]([GUID],[ITEM_IN_PACKAGE_ID],[ITEM_ID],QUANTITY)
				VALUES (NEWID(),@ITEM_IN_PACKAGE_ID,@ITEM_ID,@NOT_PASS)
			END

		END
COMMIT


	SELECT ID
	FROM prod.[STEP_OF_PALLET]
	WHERE ID = @STEP_OF_PALLET_ID

    -- Trả về thông tin package
    -- có thể tra về 2 package vì nếu có hàng lỗi
    SELECT
    P.ID packageId,
    P.SOURCE_ID fromId,
    P.DESTINATION_ID toId,
    P.CREATE_BY createBy,
    P.CREATE_DATE createDate
    FROM prod.STEP_OF_PALLET SOP
    LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOP.ID
    WHERE SOP.ID = @STEP_OF_PALLET_ID

    -- Trả về thông tin item trong package
    SELECT
	P.ID packageId,
	IIP.ID itemInPackageId,
	IIP.ITEM_ID itemId,
	IIP.QUANTITY quantity
    FROM prod.STEP_OF_PALLET SOP
    LEFT JOIN prod.PACKAGE P ON P.STEP_OF_PALLET_ID = SOP.ID
    LEFT JOIN prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
    WHERE SOP.ID = @STEP_OF_PALLET_ID
    -- Ko cần trả về nguyên liệu của pallet vì sẽ bằng chính thành phẩm.



END
GO
/****** Object:  StoredProcedure [dbo].[Proc_removePallet]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_removePallet]
@PALLET_CODE VARCHAR(20),
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN

SET XACT_ABORT ON
BEGIN TRANSACTION

DELETE MIP
FROM prod.[MATERIALS_IN_PACKAGE] MIP
LEFT JOIN prod.[ITEM_IN_PACKAGE] IIP ON IIP.ID = MIP.ITEM_IN_PACKAGE_ID
LEFT JOIN prod.[PACKAGE] P ON P.ID = IIP.PACKAGE_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOP ON SOP.ID = P.STEP_OF_PALLET_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE PL.CODE = @PALLET_CODE

DELETE IIP
FROM prod.[ITEM_IN_PACKAGE] IIP
LEFT JOIN prod.[PACKAGE] P ON P.ID = IIP.PACKAGE_ID
LEFT JOIN prod.[STEP_OF_PALLET] SOP ON SOP.ID = P.STEP_OF_PALLET_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE PL.CODE = @PALLET_CODE

DELETE P
FROM prod.[PACKAGE] P
LEFT JOIN prod.[STEP_OF_PALLET] SOP ON SOP.ID = P.STEP_OF_PALLET_ID
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE PL.CODE = @PALLET_CODE

DELETE SOP
FROM prod.[STEP_OF_PALLET] SOP
LEFT JOIN prod.[PALLET] PL ON PL.ID = SOP.PALLET_ID
WHERE PL.CODE = @PALLET_CODE

DELETE IIP
FROM prod.[ITEM_IN_PALLET] IIP
LEFT JOIN prod.[PALLET] PL ON PL.ID = IIP.PALLET_ID
WHERE PL.CODE = @PALLET_CODE


DELETE FROM prod.[PALLET]
WHERE CODE = @PALLET_CODE

COMMIT
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_ThucHienByPO]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<LMPhuong>
-- Create date: <Create Date,,>
-- Modifi date : 2021-04-08
-- Description:	Tính khối kế hoạch
-- =============================================
CREATE PROCEDURE [dbo].[Proc_ThucHienByPO]
    @code char(36)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

   select *, x.quantity - x.loiCongDon as sanLuongTruLoi, x.ton - x.xuatTon as conTon, x.keHoach - x.soLuongUuTien  + x.loiCongDon - x.quantity as conThucHien from (
            select CONCAT('PO',PO1.code) code,
    PO1.daNhanTon,
    PO1.stepId,
    PO1.number,
    PO1.week,
    PO1.year,
    PO1.market,
    PO1.ngayDongGoi,
    PO1.factoryId,
    PO1.keHoach + PO1.hanMucTon as keHoach,
    PO1.hanMucTon,
    PO1.soLuongUuTien,
	
    PO1.ys1a,
    PO1.ys1b,
    PO1.ys4,
    PO1.loiCongDon,
    PO1.xuatTon,
    D.NAME stepName,
            R.STEP_ID stepNextId,
            N.NAME stepNextName,
            orderNext.[order],
            I.Id itemId,
            I.CODE itemCode,
            I.NAME itemName,
            I.LENGTH itemLenght,
            I.WIDTH itemWidth,
            I.HEIGHT itemHeight,
            I.UNIT_ID,
            ROUND(PO1.quantity,6) 'target',
            PO1.ton,
            CASE
                WHEN SL.quantity IS NULL THEN 0
                ELSE SL.quantity
            END AS 'quantity',
            ERR.error,
            CASE
                WHEN PO1.status IS NULL THEN N'Đang sản xuất'
                ELSE PO1.status
            END AS 'status'
            --, OS.QUANTITY tonDauKy
    from prod.PO PO1
    left join prod.PO PO2 on PO2.itemId = PO1.itemId and PO2.stepId = PO1.stepId and PO2.week = PO1.week and PO2.[year] = PO1.[year]
            LEFT JOIN base.ITEM I ON I.ID = PO1.itemId
            LEFT JOIN base.DEPARTMENT D ON D.ID = PO1.stepId
            LEFT JOIN (
                SELECT PO.stepId stepId,R.[ORDER] + 1 'order'
                FROM prod.PO PO
                LEFT JOIN prod.ROUTING R ON R.ITEM_ID = PO.itemId AND PO.stepId = R.STEP_ID 
                WHERE PO.code = @code
            ) orderNext ON orderNext.stepId = PO1.stepId
            LEFT JOIN prod.ROUTING R ON R.ITEM_ID = PO1.itemId AND R.[ORDER] = orderNext.[order]
            LEFT JOIN base.DEPARTMENT N ON N.ID = R.STEP_ID
            LEFT JOIN (
                select P.PO,SUM(IIP.QUANTITY) quantity
                from prod.PACKAGE P
                left join prod.PACKAGE_TYPE PT ON PT.ID = P.TYPE_ID
                left join prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                WHERE 
                (PT.TYPE_ID <> 100000 OR PT.TYPE_ID IS NULL)
                AND (PT.TYPE_ID <> 400000 OR PT.TYPE_ID IS NULL)
                GROUP BY P.PO
            ) SL ON SL.PO = PO1.code
            LEFT JOIN (
                select P.PO,SUM(IIP.QUANTITY) error
                from prod.PACKAGE P
                left join prod.PACKAGE_TYPE PT ON PT.ID = P.TYPE_ID
                left join prod.ITEM_IN_PACKAGE IIP ON IIP.PACKAGE_ID = P.ID
                WHERE (PT.TYPE_ID = 100000 OR PT.TYPE_ID = 400000)
                GROUP BY P.PO
            ) ERR ON ERR.PO = PO1.code
            --LEFT JOIN prod.OPENING_STOCK OS ON OS.PO_ID = PO1.code

    where PO2.code = @code and R.factoryId = PO1.factoryId

	
    ) x 
		
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_verifyPackage]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_verifyPackage]
@PACKAGE_ID INT,
@TYPE_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	SET XACT_ABORT ON
BEGIN TRANSACTION
	IF NOT EXISTS (
		SELECT ID
		FROM prod.[PACKAGE]
		WHERE ID = @PACKAGE_ID
	)
	BEGIN
		ROLLBACK
		SET @ERROR = 430
		RETURN
	END
	
	UPDATE prod.[PACKAGE]
	SET [TYPE_ID] = @TYPE_ID, VERIFY_BY = @ACCOUNT_ID,VERIFY_DATE = GETDATE()
	WHERE ID = @PACKAGE_ID

COMMIT
	SELECT ID FROM prod.[PACKAGE]
	WHERE ID = @PACKAGE_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_verifyPackageWithKH]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_verifyPackageWithKH]
@PACKAGE_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN
	SET XACT_ABORT ON
BEGIN TRANSACTION
	IF NOT EXISTS (
		SELECT *
		FROM dbo.[PACKAGE]
		WHERE ID = @PACKAGE_ID
	)
	BEGIN
		SET @ERROR = 430
		RETURN
	END
	
	UPDATE dbo.[PACKAGE]
	SET KH_VERIFY_BY = @ACCOUNT_ID,KH_VERIFY_DATE = GETDATE()
	WHERE ID = @PACKAGE_ID
COMMIT

	SELECT ID FROM dbo.[PACKAGE]
	WHERE ID = @PACKAGE_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_verifyRequire]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[Proc_verifyRequire]
@REQUIRE_ID INT,
@REAL MONEY,
@ERROR_TYPE_ID INT,
@ACCOUNT_ID INT,
@ERROR INT OUTPUT
AS
BEGIN

IF EXISTS (	SELECT * 
			FROM dbo.[REQUIRE]
			WHERE ID = @REQUIRE_ID AND QC_VERIFY_BY IS NULL
		 )
	BEGIN -- nếu qc chưa xác nhận thì là qc xác nhận
		UPDATE dbo.[REQUIRE]
		SET [REAL] = @REAL, ERROR_TYPE_ID = @ERROR_TYPE_ID, QC_VERIFY_BY = @ACCOUNT_ID, QC_VERIFY_DATE = GETDATE()
		WHERE ID = @REQUIRE_ID
	END	
	ELSE -- qc đã xác nhận thì kế hoạch sẽ xác nhận
	BEGIN
		UPDATE dbo.[REQUIRE]
		SET [REAL] = @REAL, ERROR_TYPE_ID = @ERROR_TYPE_ID, KH_VERIFY_BY = @ACCOUNT_ID, KH_VERIFY_DATE = GETDATE()
		WHERE ID = @REQUIRE_ID
	END




SELECT ID
FROM dbo.[REQUIRE]
WHERE ID = @REQUIRE_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Proc_xoaDuLieuSanXuat]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Proc_xoaDuLieuSanXuat]

	-- Add the parameters for the stored procedure here
	@factoryId int,
	@number nvarchar(100)
AS


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	delete from prod.MATERIALS_IN_PACKAGE where ITEM_IN_PACKAGE_ID in (
	select ID from prod.ITEM_IN_PACKAGE where PACKAGE_ID  in(
	select ID from prod.PACKAGE where PO in(
	select code from prod.PO where number in (select distinct number from prod.PO where factoryId = @factoryId and number =@number)
	))
	)

	delete prod.ITEM_IN_PACKAGE where PACKAGE_ID  in(
	select ID from prod.PACKAGE where PO in(
	select code from prod.PO where number in (select distinct number from prod.PO where factoryId = @factoryId and number=@number)
	))

	delete prod.PACKAGE where PO in(
	select code from prod.PO where number  in (select distinct number from prod.PO where factoryId = @factoryId and number =@number)
	)

	delete from prod.PO where number  in (select distinct number from prod.PO where factoryId = @factoryId and number=@number)
END

select distinct number from prod.PO where factoryId = @factoryId and number =@number
GO
/****** Object:  StoredProcedure [dbo].[Prod_BC_Ton_Tren_Chuyen]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Prod_BC_Ton_Tren_Chuyen] 
		@stepId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT d.ID stepId , d.NAME AS stepName, i.NAME AS itemName, t.nhap,t.loi, t.xuat, t.nhap - t.loi - t.xuat as ton
		FROM (
				SELECT  n.stepId, n.itemId, n.nhap,CASE WHEN l.loi IS NULL THEN 0 ELSE l.loi END AS loi, CASE WHEN x.xuat IS NULL THEN 0 ELSE x.xuat END AS xuat
                   
				   FROM(

						  -- Nhận về
						  SELECT pa.DESTINATION_ID AS stepId, iip.ITEM_ID AS itemId, SUM(iip.QUANTITY) AS nhap
							FROM  prod.ITEM_IN_PACKAGE AS iip LEFT OUTER JOIN
							      prod.PACKAGE AS pa ON iip.PACKAGE_ID = pa.ID LEFT OUTER JOIN
								  prod.PO AS po ON pa.PO = po.code
							WHERE        (pa.TYPE_ID = 100026) 
							--Lọc theo công đoạn nhận về
							AND pa.DESTINATION_ID = @stepId
							AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL)
							--Lọc theo thời gian


							GROUP BY pa.DESTINATION_ID, iip.ITEM_ID
						  -- End nhận về
						  ) AS n LEFT OUTER JOIN (
												   
						  -- Trừ phôi
						  SELECT pa.SOURCE_ID AS stepId, mip.ITEM_ID AS itemId, SUM(mip.QUANTITY) AS xuat
							FROM  prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
								  prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
								  prod.PACKAGE AS pa ON pa.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                                  prod.PO AS po ON pa.PO = po.code
							WHERE        (pa.TYPE_ID = 100026)
							--Lọc theo công đoạn giao đi
							AND pa.SOURCE_ID = @stepId
							AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL)
							--Lọc theo thời gian


							GROUP BY pa.SOURCE_ID, mip.ITEM_ID
							-- End trừ phôi
							) AS x ON n.itemId = x.itemId AND n.stepId = x.stepId LEFT OUTER JOIN (
							
							-- Lỗi công đoạn
							SELECT pa.SOURCE_ID AS stepId, mip.ITEM_ID AS itemId, SUM(mip.QUANTITY) AS loi
							FROM  prod.MATERIALS_IN_PACKAGE AS mip LEFT OUTER JOIN
								  prod.ITEM_IN_PACKAGE AS iip ON iip.ID = mip.ITEM_IN_PACKAGE_ID LEFT OUTER JOIN
								  prod.PACKAGE AS pa ON pa.ID = iip.PACKAGE_ID LEFT OUTER JOIN
                                  prod.PO AS po ON pa.PO = po.code
							WHERE        (pa.TYPE_ID = 100004)
							--Lọc theo công đoạn giao đi
							AND pa.SOURCE_ID = @stepId
							AND (pa.PO IS NOT NULL) AND (po.deletedAt IS NULL)
							--Lọc theo thời gian


							GROUP BY pa.SOURCE_ID, mip.ITEM_ID
							) as l on l.itemId = n.itemId and l.stepId = n.stepId						
							) AS t LEFT OUTER JOIN



                         -- lấy tên công đoạn và tên quy cách sản phẩm
						 base.DEPARTMENT AS d ON t.stepId = d.ID LEFT OUTER JOIN
                         base.ITEM AS i ON t.itemId = i.ID
				
				-- Hiển thị theo tên công đoạn sắp xếp tăng
				ORDER BY stepName
  
  -- Kết thúc thủ tục
END
GO
/****** Object:  StoredProcedure [eof].[Proc_GetDataDashboard]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<HTHIEU>
-- Create date: <2021-03-29>
-- Description:	<l?y ra báo cáo s? li?u các phi?u trên ph?n m?m bi?u di?n b?ng dashboard>
-- =============================================
CREATE PROCEDURE [eof].[Proc_GetDataDashboard]
	-- Add the parameters for the stored procedure here
	@option int,  -- tùy chọn hiển thị  : 0 - lấy báo cáo tổng phiếu trên toàn hệ thống  1-- lấy tùy chọn thời gian theo phòng ban ; 2-- lấy tỉ lệ thông báo đc gửi qua mail - app eoffice
	@day int, -- tùy chọn khoảng thời gian hiển thị 
	@departmentId int -- phòng ban cần hiển thị dữ liệu theo giời gian đã định
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--select SubString(CAst(createdAt as varchar),0,11) from eof.Orders 
    -- Insert statements for procedure here
	if (@option = 0 )
	begin
		
		select * from (
          select   count(*) as total ,  case 
              when slug ='mua-hang' and o.proposalFormId = 1028 then N'Phiếu mua hàng/cấp vật tư sửa chữa tiêu hao'
              when slug ='mua-hang' and o.proposalFormId = 1029 then N'Phiếu mua hàng/cấp vật tư chế tạo'
              when slug ='mua-hang' and o.proposalFormId = 1026 then N'Phiếu mua hàng/cấp vật tư khối dự án'
              when slug ='mua-hang' and o.proposalFormId = 1031 then N'Phiếu mua hàng/cấp vật tư khối ván công nghiệp'
              when slug ='mua-hang' and o.proposalFormId = 3 then N'Phiếu mua hàng/cấp vật tư NM Thuận Hưng'
              when slug ='xac-nhan-cong' then N'Phiếu làm thêm giờ'
              when slug ='xin-ra-cong' then N'Phiếu xin ra cổng'
              when slug ='di-cong-tac' then N'Phiếu đề nghị đi công tác'
              end as [order] from eof.Orders o
              where o.createdAt between GETDATE() - @day and GETDATE() and deletedAt is null   group by slug , proposalFormId
          union all
          select   count(*) as total ,  
          case 
              when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ phép' then  N'Phiếu xin nghỉ phép'
          when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ ốm' then  N'Phiếu xin nghỉ ốm'
          when o.slug ='xin-nghi-viec' and om.selection = N'Xin nghỉ Thai sản' then  N'Phiếu Xin nghỉ Thai sản'
          when o.slug ='xin-nghi-viec' and om.selection = N'Xin nghỉ không lương' then  N'Phiếu Xin nghỉ không lương'
          when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ việc riêng có hưởng lương' then  N'Phiếu Nghỉ việc riêng có hưởng lương'
              end as [order] from eof.Orders o
          left join eof.OrderMeta om on om.orderId = o.id
              where o.createdAt between GETDATE() - @day and GETDATE() and deletedAt is null  and o.proposalFormId =16  group by slug , proposalFormId , om.selection
		)as X where X.[order] is not null
	end
	else if (@option = 1)
	begin
		select * from (
          select   count(*) as total ,  case 
              when slug ='mua-hang' and o.proposalFormId = 1028 then N'Phiếu mua hàng/cấp vật tư sửa chữa tiêu hao'
              when slug ='mua-hang' and o.proposalFormId = 1029 then N'Phiếu mua hàng/cấp vật tư chế tạo'
              when slug ='mua-hang' and o.proposalFormId = 1026 then N'Phiếu mua hàng/cấp vật tư khối dự án'
              when slug ='mua-hang' and o.proposalFormId = 1031 then N'Phiếu mua hàng/cấp vật tư khối ván công nghiệp'
              when slug ='mua-hang' and o.proposalFormId = 3 then N'Phiếu mua hàng/cấp vật tư NM Thuận Hưng'
              when slug ='xac-nhan-cong' then N'Phiếu làm thêm giờ'
              when slug ='xin-ra-cong' then N'Phiếu xin ra cổng'
              when slug ='di-cong-tac' then N'Phiếu đề nghị đi công tác'
              end as [order] from eof.Orders o
              where o.createdAt between GETDATE() - @day and GETDATE() and deletedAt is null and o.departmentId = @departmentId and o.completed =1   group by slug , proposalFormId
          union all
          select   count(*) as total ,  
          case 
              when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ phép' then  N'Phiếu xin nghỉ phép'
          when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ ốm' then  N'Phiếu xin nghỉ ốm'
          when o.slug ='xin-nghi-viec' and om.selection = N'Xin nghỉ Thai sản' then  N'Phiếu Xin nghỉ Thai sản'
          when o.slug ='xin-nghi-viec' and om.selection = N'Xin nghỉ không lương' then  N'Phiếu Xin nghỉ không lương'
          when o.slug ='xin-nghi-viec' and om.selection = N'Nghỉ việc riêng có hưởng lương' then  N'Phiếu Nghỉ việc riêng có hưởng lương'
              end as [order] from eof.Orders o
          left join eof.OrderMeta om on om.orderId = o.id
              where o.createdAt between GETDATE() - @day and GETDATE() and deletedAt is null  and o.proposalFormId =16 and o.departmentId = @departmentId and o.completed =1  group by slug , proposalFormId , om.selection
		)as X where X.[order] is not null
	end
	else if(@option = 2)
	begin
		select COUNT(*) as total , 'Mail' as [option] 
		from eof.NotificationDetail 
		where email is not null and createdAt between GETDATE() - @day and GETDATE()
		union all
		select COUNT(*) as total , N'Ứng dụng Eoffice' as [option] 
		from eof.NotificationDetail  
		where email is  null and createdAt between GETDATE() - @day and GETDATE()
	end
END
GO
/****** Object:  StoredProcedure [eof].[Proc_UpdateRequest]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<HTHIEU	>
-- Create date: <2020/11/14>
-- Description:	<th? t?c c?p nh?t request sau 2 ngày >
-- exec [eof].[Proc_UpdateRequest]
-- =============================================
CREATE PROCEDURE [eof].[Proc_UpdateRequest]
AS
BEGIN
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	if(exists(select orderId from eof.Requests  where DATEDIFF(MINUTE,createdAt,SYSDATETIMEOFFSET()) > 2 and show = 1 and status = N'Chưa ký'))
	begin
		update eof.Requests 
		set status = N'Quá hạn' , updatedAt = SYSDATETIMEOFFSET() 
		from eof.Requests 
		where id in (select id from eof.Requests where step  in  (select step as nextStep from eof.Requests  where DATEDIFF(MINUTE,createdAt,SYSDATETIMEOFFSET()) > 2 and show = 1 and status = N'Chưa ký'))
		update eof.Requests 
			set show = 1
			from eof.Requests 
			where id in (select id from eof.Requests where step  in  (select (step + 1) as nextStep from eof.Requests  where DATEDIFF(MINUTE,createdAt,SYSDATETIMEOFFSET()) > 2 and DATEDIFF(MINUTE,updatedAt,SYSDATETIMEOFFSET()) < 2 and show = 1 and status = N'Quá hạn' ))
			print('abc')
	end
	
END
GO
/****** Object:  StoredProcedure [nlg].[getBCKHThang]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [nlg].[getBCKHThang] @thang as int,@year as int
as
declare @week int
set @week = DATEPART(week,CAST(@year as nvarchar(20))+'-'+CAST(@thang as nvarchar(20))+'-01')
SELECT a.CODE,SUM(a.KH) as [KH_MONTH], SUM(a.THUCHIEN) as [TH_MONTH],ISNULL(CAST(SUM(a.THUCHIEN)/NULLIF(SUM(a.KH), 0)*100 as decimal(16,2)),0)  as [TYLE],
SUM(a.[WEEK1]) as 'W1',SUM(a.[WEEK2]) as 'W2',SUM(a.[WEEK3]) as 'W3',SUM(a.[WEEK4]) as 'W4'
FROM
(
-- THUC HIEN / THNAG
SELECT CODE,0 AS [KH],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [THUCHIEN],
0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N') AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
---KE HOACH/THNAG
UNION ALL
SELECT CODE,SUM(PLANQTY) AS KH,0 AS [THUCHIEN],0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PLAN_nlg
WHERE DEL_FLAG='N' AND DATEPART(MONTH,CREATED_AT)=@thang AND DATEPART(YEAR,CREATED_AT)=@year 
GROUP BY CODE
---WEEK1
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK1],
0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = CAST(@week as int) AND DATEPART(YEAR,CREATED_AT)=@year  AND DEL_FLAG='N')
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE

--WEEK2
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK2],
0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+1 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N')
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
--WEEK3
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],0 AS [WEEK2],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK3],
0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+2 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N')
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE

--WEEK4
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+3 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N')
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
) AS a
GROUP by a.CODE
order by TYLE desc
GO
/****** Object:  StoredProcedure [nlg].[getBCKHThangByStaff]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [nlg].[getBCKHThangByStaff] @thang as int,@year as int,@staff as nvarchar(20)
as
declare @week int
set @week = DATEPART(week,CAST(@year as nvarchar(20))+'-'+CAST(@thang as nvarchar(20))+'-01')
SELECT a.CODE,SUM(a.KH) as [KH_MONTH], SUM(a.THUCHIEN) as [TH_MONTH],ISNULL(CAST(SUM(a.THUCHIEN)/NULLIF(SUM(a.KH), 0)*100 as decimal(16,2)),0)  as [TYLE],
SUM(a.[WEEK1]) as 'W1',SUM(a.[WEEK2]) as 'W2',SUM(a.[WEEK3]) as 'W3',SUM(a.[WEEK4]) as 'W4'
FROM
(
-- THUC HIEN / THNAG
SELECT CODE,0 AS [KH],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [THUCHIEN],
0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT
WHERE SOPHIEUNHAP IN (
SELECT SOPHIEU FROM PHIEUNHAPKHO 
WHERE DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N' AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE DEL_FLAG='N' AND STAFF=@staff)) 
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
---KE HOACH/THNAG
UNION ALL
SELECT CODE,SUM(PLANQTY) AS KH,0 AS [THUCHIEN],0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PLAN_nlg
WHERE DEL_FLAG='N' AND DATEPART(MONTH,CREATED_AT)=@thang AND DATEPART(YEAR,CREATED_AT)=@year AND CREATE_BY=@staff
GROUP BY CODE
---WEEK1
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK1],
0 AS [WEEK2],0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = CAST(@week as int) AND DATEPART(YEAR,CREATED_AT)=@year  AND DEL_FLAG='N' AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE DEL_FLAG='N' AND STAFF=@staff))
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE

--WEEK2
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK2],
0 AS [WEEK3],0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+1 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N'  AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE DEL_FLAG='N' AND STAFF=@staff))
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
--WEEK3
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],0 AS [WEEK2],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK3],
0 AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+2 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N'  AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE DEL_FLAG='N' AND STAFF=@staff))
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE

--WEEK4
UNION ALL
SELECT CODE,0 AS [KH],0 AS [THUCHIEN], 0 AS [WEEK1],0 AS [WEEK2],0 AS [WEEK3],
SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4))) AS [WEEK4]
FROM PHIEUNHAPKHO_DT 
WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE DATEPART(WEEK,CREATED_AT) = @week+3 AND DATEPART(YEAR,CREATED_AT)=@year AND DATEPART(MONTH,CREATED_AT) = @thang AND DEL_FLAG='N'  AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE DEL_FLAG='N' AND STAFF=@staff))
AND DEL_FLAG='N' AND DELAI='N'
GROUP BY CODE
) AS a
GROUP by a.CODE
order by TYLE DESC
GO
/****** Object:  StoredProcedure [nlg].[getBCKHThangByVendor]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [nlg].[getBCKHThangByVendor] @fromDate as DATETIME,@toDate as DATETIME,@monthOfPlan as INT,@staff as varchar(30),@mancc as varchar(30),@YEAR_OF_PLAN as int
AS
-- TRƯỜNG HỢP KHÔNG CHỌN NHÂN VIÊN VÀ NHÀ CUNG CẤP
IF @staff='all' AND @mancc='all' 
	BEGIN
		-- THUC HIEN
		SELECT  GR.NAME AS [CODE],0 AS [KH],
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N') 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH], 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN
	END
-- TRƯỜNG HỢP CHỌN CẢ NHÂN VIÊN VÀ NHÀ CUNG CẤP
IF NOT @staff ='all' and NOT @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N') 
		AND PT.DEL_FLAG='N' AND DELAI='N' AND PN.MANCC=@mancc AND PR.STAFF=@staff

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH], 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN AND PL.MANCC=@mancc
	END
-- TRƯỜNG HỢP CHỈ CHỌN NHÂN VIÊN
IF NOT @staff ='all' and  @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N'
			AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE STAFF=@staff)
		) 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH], 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN AND PL.CREATE_BY = @staff
	END
-- TRƯỜNG HỢP CHỈ CHỌN nhà cung cấp
IF  @staff ='all' and NOT @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N'
			AND MANCC = @mancc
		) 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH], 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN AND PL.MANCC=@mancc
	END

GO
/****** Object:  StoredProcedure [nlg].[getBCKHThangByVendor_V2]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE     PROCEDURE [nlg].[getBCKHThangByVendor_V2] @fromDate as DATETIME,@toDate as DATETIME,@monthOfPlan as INT,@staff as varchar(30),@mancc as varchar(30)
AS

DECLARE @YEAR_OF_PLAN INT
SET @YEAR_OF_PLAN = DATEPART(YEAR,@fromDate)
-- TRƯỜNG HỢP KHÔNG CHỌN NHÂN VIÊN VÀ NHÀ CUNG CẤP
IF @staff='all' AND @mancc='all' 
	BEGIN
		-- THUC HIEN
		SELECT  GR.NAME AS [CODE],0 AS [KH],SOPHIEUNHAP,
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N') 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH],'0' as SOPHIEUNHAP, 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN
	END
-- TRƯỜNG HỢP CHỌN CẢ NHÂN VIÊN VÀ NHÀ CUNG CẤP
IF NOT @staff ='all' and NOT @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],SOPHIEUNHAP,
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N') 
		AND PT.DEL_FLAG='N' AND DELAI='N' AND PN.MANCC=@mancc AND PR.STAFF=@staff

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH],'0' as SOPHIEUNHAP, 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN AND  PL.CREATE_BY = @staff AND PL.MANCC=@mancc
	END
-- TRƯỜNG HỢP CHỈ CHỌN NHÂN VIÊN
IF NOT @staff ='all' and  @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],SOPHIEUNHAP,
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N'
			AND MANCC IN (SELECT CODE FROM PROVIDERS WHERE STAFF=@staff)
		) 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH],'0' as SOPHIEUNHAP, 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND  DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN AND PL.CREATE_BY = @staff
	END

-- 2019-13-03
-- TRƯỜNG HỢP CHỈ CHỌN NHÀ CUNG CẤP KHÔNG CHỌN NHÂN VIÊN
IF @staff ='all' AND NOT  @mancc = 'all'
	BEGIN
		SELECT GR.NAME AS [CODE],0 AS [KH],SOPHIEUNHAP,
		CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)) AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR],PN.MAKHO,
			CASE WHEN DATEPART(WEEKDAY,PN.CREATED_AT)=7 THEN DATEPART(WEEK,PN.CREATED_AT)+1 ELSE DATEPART(WEEK,PN.CREATED_AT) END AS [WEEK],PR.STAFF
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		INNER JOIN GROUP_CODE AS GR ON GR.ID=PT.CODENHOM
		WHERE SOPHIEUNHAP IN (SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE CREATED_AT BETWEEN @fromDate AND @toDate AND DEL_FLAG='N'
			AND MANCC = @mancc
		) 
		AND PT.DEL_FLAG='N' AND DELAI='N'

		UNION ALL
		SELECT GR.NAME AS [CODE], PL.PLANQTY AS [KH],'0' as SOPHIEUNHAP, 0 AS [THUCHIEN],PR.CODE AS [CODE_VENDOR],PR.NAME AS [NAME_VENDOR], 'TH' AS [MAKHO],
		CASE WHEN DATEPART(WEEKDAY,PL.CREATED_AT)=7 THEN DATEPART(WEEK,PL.CREATED_AT)+1 ELSE DATEPART(WEEK,PL.CREATED_AT) END AS [WEEK],PL.CREATE_BY AS [STAFF]
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		INNER JOIN GROUP_CODE AS GR ON  GR.ID =PL.GROUP_CODE
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = @monthOfPlan AND DATEPART(YEAR,CREATED_AT)=@YEAR_OF_PLAN  AND PL.MANCC = @mancc
	END
GO
/****** Object:  StoredProcedure [nlg].[GetStockAllLocation]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- tồn kho theO tuần, theo kho việt hà

CREATE PROCEDURE [nlg].[GetStockAllLocation] @cweek as int,@cyear as int
as

--GET INPUTSTOCK
--GET INPUTSTOCK KHO VIETHA 
  SELECT  s.CODE,SUM(q.STOCKQTY + POWER(Cast(10 as float),CAST(-9 as float)) * s.SOBO*s.SOTHANH_BO*s.DAY*s.RONG*s.CAO-
	ISNULL(r.DAY*r.RONG*r.DAI*r.TONGSOTHANH*POWER(CAST(10 as float),CAST(-9 as float)), 0 )) AS N'INPUTSTOCK_VH',
	0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',-- TON DAU KY CUA CAC KHO
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
	FROM PHIEUNHAPKHO_DT AS s 
	INNER JOIN  PHIEUNHAPKHO as p
	ON s.SOPHIEUNHAP = p.SOPHIEU
	inner JOIN STOCK AS q
	on s.CODE = q.MANVL and q.MAKHO='VH'
	LEFT JOIN PHIEUXUATKHO_DT AS r
	ON s.CODE = r.CODE
	where DATEPART(WEEK,s.CREATED_AT) < @cweek AND DATEPART(year,s.CREATED_AT)=@cyear
	group by s.CODE,p.MAKHO
	HAVING  p.MAKHO='VH'
  UNION 
  --GET INPUTSTOCK KHO THUAN HUNG
  SELECT  s.CODE,0 AS N'INPUTSTOCK_VH',SUM(q.STOCKQTY + POWER(Cast(10 as float),CAST(-9 as float)) * s.SOBO*s.SOTHANH_BO*s.DAY*s.RONG*s.CAO-
	ISNULL(r.DAY*r.RONG*r.DAI*r.TONGSOTHANH*POWER(CAST(10 as float),CAST(-9 as float)), 0 )) AS 'INPUTSTOCK_TH',
  0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',-- TON DAU KY CUA CAC KHO
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
	FROM PHIEUNHAPKHO_DT AS s 
	INNER JOIN  PHIEUNHAPKHO as p
	ON s.SOPHIEUNHAP = p.SOPHIEU
	inner JOIN STOCK AS q
	on s.CODE = q.MANVL and q.MAKHO='TH'
	LEFT JOIN PHIEUXUATKHO_DT AS r
	ON s.CODE = r.CODE
	where DATEPART(WEEK,s.CREATED_AT) < @cweek AND DATEPART(year,s.CREATED_AT)=@cyear
	group by s.CODE,p.MAKHO
	HAVING  p.MAKHO='TH'
  UNION 
  --GET INPUTSTOCK KHO THAI BINH
SELECT  s.CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',SUM(q.STOCKQTY + POWER(Cast(10 as float),CAST(-9 as float)) * s.SOBO*s.SOTHANH_BO*s.DAY*s.RONG*s.CAO-
	ISNULL(r.DAY*r.RONG*r.DAI*r.TONGSOTHANH*POWER(CAST(10 as float),CAST(-9 as float)), 0 )) AS 'INPUTSTOCK_TB',
	0 AS 'INPUTSTOCK_WL',-- TON DAU KY CUA CAC KHO
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
	FROM PHIEUNHAPKHO_DT AS s 
	INNER JOIN  PHIEUNHAPKHO as p
	ON s.SOPHIEUNHAP = p.SOPHIEU
	inner JOIN STOCK AS q
	on s.CODE = q.MANVL and q.MAKHO='TB'
	LEFT JOIN PHIEUXUATKHO_DT AS r
	ON s.CODE = r.CODE
	where DATEPART(WEEK,s.CREATED_AT) < @cweek AND DATEPART(year,s.CREATED_AT)=@cyear
	group by s.CODE,p.MAKHO
	HAVING  p.MAKHO='TB'
UNION 
  --GET INPUTSTOCK KHO WOODSLAND
SELECT  s.CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',
	SUM(q.STOCKQTY + POWER(Cast(10 as float),CAST(-9 as float)) * s.SOBO*s.SOTHANH_BO*s.DAY*s.RONG*s.CAO-
	ISNULL(r.DAY*r.RONG*r.DAI*r.TONGSOTHANH*POWER(CAST(10 as float),CAST(-9 as float)), 0 )) AS 'INPUTSTOCK_WL',-- TON DAU KY CUA CAC KHO
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
	FROM PHIEUNHAPKHO_DT AS s 
	INNER JOIN  PHIEUNHAPKHO as p
	ON s.SOPHIEUNHAP = p.SOPHIEU
	inner JOIN STOCK AS q
	on s.CODE = q.MANVL and q.MAKHO='WL'
	LEFT JOIN PHIEUXUATKHO_DT AS r
	ON s.CODE = r.CODE
	where DATEPART(WEEK,s.CREATED_AT) < @cweek AND DATEPART(year,s.CREATED_AT)=@cyear
	group by s.CODE,p.MAKHO
	HAVING  p.MAKHO='WL'
UNION 
  --LẤY NHẬP  KHO Việt Hà (nhập hàng từ ncc về)
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
	SUM(POWER(CAST(10 as float),CAST(-9 as float))*SOBO* SOTHANH_BO*DAY*RONG*CAO) AS 'NCC_TO_VH',
	0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  
      FROM PHIEUNHAPKHO_DT
      INNER JOIN PHIEUNHAPKHO ON PHIEUNHAPKHO.SOPHIEU = PHIEUNHAPKHO_DT.SOPHIEUNHAP
      WHERE DATEPART(WEEK,PHIEUNHAPKHO_DT.CREATED_AT)= @cweek AND PHIEUNHAPKHO_DT.DEL_FLAG='N' AND DATEPART(year,PHIEUNHAPKHO_DT.CREATED_AT)=@cyear
      AND PHIEUNHAPKHO.MAKHO='VH'
	GROUP BY CODE 
  
UNION
  --LẤY NHẬP  KHO THUAN HUNG (nhập hàng từ ncc về)
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
	0 AS 'NCC_TO_VH',
	SUM(POWER(CAST(10 as float),CAST(-9 as float))*SOBO* SOTHANH_BO*DAY*RONG*CAO) AS 'NCC_TO_TH',
	0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  
      FROM PHIEUNHAPKHO_DT
      INNER JOIN PHIEUNHAPKHO ON PHIEUNHAPKHO.SOPHIEU = PHIEUNHAPKHO_DT.SOPHIEUNHAP
      WHERE DATEPART(WEEK,PHIEUNHAPKHO_DT.CREATED_AT)= @cweek AND PHIEUNHAPKHO_DT.DEL_FLAG='N' AND DATEPART(year,PHIEUNHAPKHO_DT.CREATED_AT)=@cyear
      AND PHIEUNHAPKHO.MAKHO='TH'
	GROUP BY CODE 
UNION
--LẤY NHẬP  KHO THAI BINH  (nhập hàng từ ncc về)
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',
	SUM(POWER(CAST(10 as float),CAST(-9 as float))*SOBO* SOTHANH_BO*DAY*RONG*CAO) AS 'NCC_TO_TB',
	0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  
      FROM PHIEUNHAPKHO_DT
      INNER JOIN PHIEUNHAPKHO ON PHIEUNHAPKHO.SOPHIEU = PHIEUNHAPKHO_DT.SOPHIEUNHAP
      WHERE DATEPART(WEEK,PHIEUNHAPKHO_DT.CREATED_AT)= @cweek AND PHIEUNHAPKHO_DT.DEL_FLAG='N' AND DATEPART(year,PHIEUNHAPKHO_DT.CREATED_AT)=@cyear
      AND PHIEUNHAPKHO.MAKHO='TB'
	GROUP BY CODE 
UNION
--LẤY NHẬP  KHO WOODSLAND  (nhập hàng từ ncc về)
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
	0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',
	SUM(POWER(CAST(10 as float),CAST(-9 as float))*SOBO* SOTHANH_BO*DAY*RONG*CAO) AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
	0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
	0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
	0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
	0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  
      FROM PHIEUNHAPKHO_DT
      INNER JOIN PHIEUNHAPKHO ON PHIEUNHAPKHO.SOPHIEU = PHIEUNHAPKHO_DT.SOPHIEUNHAP
      WHERE DATEPART(WEEK,PHIEUNHAPKHO_DT.CREATED_AT)= @cweek AND PHIEUNHAPKHO_DT.DEL_FLAG='N' AND DATEPART(year,PHIEUNHAPKHO_DT.CREATED_AT)=@cyear
      AND PHIEUNHAPKHO.MAKHO='WL'
	GROUP BY CODE 
UNION
--VIET HA XUẤT SANG THUAN HUNG
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'VH_TO_TH',
		0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='VH' AND PHIEUXUATKHO.TOSL='TH'
  GROUP BY CODE
UNION
--VIET HA XUẤT SANG THAI BINH
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'VH_TO_TB',
		0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='VH' AND PHIEUXUATKHO.TOSL='TB'
  GROUP BY CODE
UNION
--VIET HA XUẤT SANG WOODSLAND
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'VH_TO_WL',
		0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='VH' AND PHIEUXUATKHO.TOSL='WL'
  GROUP BY CODE
UNION
--VIET HA XUẤT SANG SAN XUAT
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='VH' AND PHIEUXUATKHO.TOSL='PROD'
  GROUP BY CODE
UNION
--THUAN HUNG XUẤT SANG VIET HA
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TH_TO_VH',
		0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TH' AND PHIEUXUATKHO.TOSL='VH'
  GROUP BY CODE
UNION

--DANG SUA
--THUAN HUNG XUẤT SANG THAI BINH
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TH_TO_TB',
		0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TH' AND PHIEUXUATKHO.TOSL='TB'
  GROUP BY CODE
UNION
--THUAN HUNG XUẤT SANG WOODSLAND
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TH_TO_WL',
		0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TH' AND PHIEUXUATKHO.TOSL='WL'
  GROUP BY CODE
UNION
--THUAN HUNG XUẤT SANG SAN XUAT
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TH' AND PHIEUXUATKHO.TOSL='PROD'
  GROUP BY CODE
UNION
--THAI BINH XUAT SANG THUAN HUNG
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TB_TO_TH',
		0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TB' AND PHIEUXUATKHO.TOSL='TH'
  GROUP BY CODE
UNION
--THAI BINH XUAT SANG VIET HA
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TB_TO_VH',
		0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TB' AND PHIEUXUATKHO.TOSL='VH'
  GROUP BY CODE
UNION
--THAI BINH XUAT SANG WOODSLAND
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TB_TO_WL',
		0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TB' AND PHIEUXUATKHO.TOSL='WL'
  GROUP BY CODE
UNION
--THAI BINH XUAT SANG SAN XUAT
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='TB' AND PHIEUXUATKHO.TOSL='PROD'
  GROUP BY CODE
UNION
--WOODSLAND XUAT SANG THUAN HUNG
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'WL_TO_TH',
		0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='WL' AND PHIEUXUATKHO.TOSL='TH'
  GROUP BY CODE
UNION
--WOODSLAND XUAT SANG THAI BINH
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'WL_TO_TB',
		0 AS 'WL_TO_VH',0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='WL' AND PHIEUXUATKHO.TOSL='TB'
  GROUP BY CODE
UNION
--WOODSLAND XUAT SANG VIET HA
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'WL_TO_VH',
		0 AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='WL' AND PHIEUXUATKHO.TOSL='VH'
  GROUP BY CODE
UNION
--WOODSLAND XUAT SANG SAN XUAT
SELECT CODE,0 AS N'INPUTSTOCK_VH',0 AS 'INPUTSTOCK_TH',0 AS 'INPUTSTOCK_TB',0 AS 'INPUTSTOCK_WL',
		0 AS 'NCC_TO_VH',0 AS 'NCC_TO_TH',0 AS 'NCC_TO_TB',0 AS 'NCC_TO_WL', --CAC KHO NHAN TU NHA CUNG CAP
		0 AS 'VH_TO_TH',0 AS 'VH_TO_TB',0 AS 'VH_TO_WL',0 AS 'VH_TO_PROD',--VIET HA XUAT DI CAC KHO
		0 AS 'TH_TO_VH',0 AS 'TH_TO_TB',0 AS 'TH_TO_WL',0 AS 'TH_TO_PROD',--THUAN HUNG XUAT DI CAC KHO
		0 AS 'TB_TO_TH',0 AS 'TB_TO_VH',0 AS 'TB_TO_WL',0 AS 'TB_TO_PROD',--THAI BINH XUAT DI CAC KHO
		0 AS 'WL_TO_TH',0 AS 'WL_TO_TB',0 AS 'WL_TO_VH',
		SUM(POWER(CAST(10 as float),CAST(-9 as float))*TONGSOTHANH*DAY*RONG*DAI) AS 'WL_TO_PROD'--WL XUAT DI CAC KHO
  FROM PHIEUXUATKHO_DT 
  INNER JOIN PHIEUXUATKHO ON PHIEUXUATKHO.SOPHIEUXUAT = PHIEUXUATKHO_DT.SOPHIEUXUAT
  WHERE DATEPART(WEEK,PHIEUXUATKHO.CREATED_AT)=@cweek AND DATEPART(year,PHIEUXUATKHO.CREATED_AT)=@cyear
  AND PHIEUXUATKHO_DT.DEL_FLAG='N' AND PHIEUXUATKHO.FROMSL='WL' AND PHIEUXUATKHO.TOSL='PROD'
  GROUP BY CODE
  
GO
/****** Object:  StoredProcedure [nlg].[proc_add_data_to_instock_detail]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [nlg].[proc_add_data_to_instock_detail] 
	@DAY AS INT,-- CHIỀU DẦY
	@RONG AS INT,-- CHIỀU RỘNG
	@DAI AS INT , -- CHIỀU DÀI
	@SOBO AS INT , -- SỐ BÓ NHẬP
	@SOTHANHBO AS INT , --SỐ THANH/ BÓ
	@SOPHIEU AS VARCHAR(40), -- SỐ PHIẾU NHẬP KHO
	@CODE AS VARCHAR(40) , -- MÃ QUI CÁCH
	@NOTE AS NVARCHAR(300), -- GHI CHÚ
	@OVER AS BIT, -- VƯỢT KẾ HOẠCH HAY KHÔNG,
	@USERNAME AS VARCHAR(50), --TÊN ĐĂNG NHẬP , CỦA NGƯỜI TẠO
	@NOTEHACAP AS NCHAR(10)-- KIỂU NHẬP
AS
BEGIN
	BEGIN TRANSACTION
			--KHAI BÁO 1 SỐ BIẾN CẦN DÙNG
			DECLARE @VUNG AS CHAR(10),@MANVL AS VARCHAR(40),@MANCC  AS NVARCHAR(30),@RESULT AS BIT,@CODENHOM AS VARCHAR(50)
			-- LẤY THÔNG TIN VÙNG CỦA BIÊN BẢN NHẬP KHO
			SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@SOPHIEU
			SELECT @VUNG = CODE FROM PROVIDERS WHERE CODE=@MANCC
			SELECT TOP 1 @CODENHOM = NHOM FROM BOM WHERE CODE=TRIM(@CODE)
			-- LẤY MÃ NGUYÊN VẬT LIỆU CỦA MÃ QUI CÁCH
			IF TRIM(@VUNG) = 'QT'
			-- NẾU LÀ VÙNG QUẢNG TRỊ LẤY BẢNG GIÁ CÓ MÃ QT
				SELECT TOP 1 @MANVL = MANVL FROM nlgO WHERE MANVLKHO=@CODE AND SUBSTRING(MANVL,0,3)='QT'
			ELSE
			--NGƯỢC LẠI
				SELECT TOP 1 @MANVL = MANVL FROM nlgO WHERE MANVLKHO=@CODE AND NOT SUBSTRING(MANVL,0,3)='QT'
			PRINT(N'-----------------------ĐÃ LẤY ĐƯỢC MÃ GIÁ SẢN PHẨM : '+@MANVL)

			IF LEN(@MANVL)>0 
				BEGIN
					INSERT INTO PHIEUNHAPKHO_DT(SOPHIEUNHAP, [DAY], RONG, CAO, SOBO, SOTHANH_BO, NOTE, 
												CREATED_AT, CREATED_BY, DEL_FLAG,DELAI,SAMPLEQTY,QTY,MANVL,
												QC_INSPECTOR,DONGIA_CTY,DONGIA_LOAI,NOTEHACAP,CODE,OVER_PLAN,CODENHOM)
												VALUES(@SOPHIEU,@DAY,@RONG,@DAI,@SOBO,@SOTHANHBO,@NOTE,GETDATE(),@USERNAME,
												'N','N',0,0,@MANVL,'N',0,0,@NOTEHACAP,@CODE,@OVER,@CODENHOM)
					SELECT @RESULT = 1
					COMMIT
				END
			ELSE
				BEGIN
					SELECT @RESULT = 0
					ROLLBACK
				END
			
			SELECT @RESULT AS RESULT
END
GO
/****** Object:  StoredProcedure [nlg].[proc_add_data_to_instock_detail_khackho]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [nlg].[proc_add_data_to_instock_detail_khackho]
	-- Add the parameters for the stored procedure here
	@DAY AS INT,-- CHIỀU DẦY
	@RONG AS INT,-- CHIỀU RỘNG
	@DAI AS INT , -- CHIỀU DÀI
	@SOBO AS INT , -- SỐ BÓ NHẬP
	@SOTHANHBO AS INT , --SỐ THANH/ BÓ
	@SOPHIEU AS VARCHAR(40), -- SỐ PHIẾU NHẬP KHO
	@CODE AS VARCHAR(40) , -- MÃ QUI CÁCH
	@NOTE AS NVARCHAR(300), -- GHI CHÚ
	@OVER AS BIT, -- VƯỢT KẾ HOẠCH HAY KHÔNG,
	@USERNAME AS VARCHAR(50), --TÊN ĐĂNG NHẬP , CỦA NGƯỜI TẠO
	@NOTEHACAP AS NCHAR(10),-- KIỂU NHẬP
	@KHACKHO AS BIT
AS
BEGIN
	BEGIN TRANSACTION
			--KHAI BÁO 1 SỐ BIẾN CẦN DÙNG
			DECLARE @VUNG AS CHAR(10),@MANVL AS VARCHAR(40),@MANCC  AS NVARCHAR(30),@RESULT AS BIT,@CODENHOM AS VARCHAR(50)
			-- LẤY THÔNG TIN VÙNG CỦA BIÊN BẢN NHẬP KHO
			SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@SOPHIEU
			SELECT @VUNG = CODE FROM PROVIDERS WHERE CODE=@MANCC
			SELECT TOP 1 @CODENHOM = NHOM FROM BOM WHERE CODE=TRIM(@CODE)
			-- LẤY MÃ NGUYÊN VẬT LIỆU CỦA MÃ QUI CÁCH
			IF TRIM(@VUNG) = 'QT'
			-- NẾU LÀ VÙNG QUẢNG TRỊ LẤY BẢNG GIÁ CÓ MÃ QT
				SELECT TOP 1 @MANVL = MANVL FROM nlgO WHERE MANVLKHO=@CODE AND SUBSTRING(MANVL,0,3)='QT'
			ELSE
			--NGƯỢC LẠI
				SELECT TOP 1 @MANVL = MANVL FROM nlgO WHERE MANVLKHO=@CODE AND NOT SUBSTRING(MANVL,0,3)='QT'
			PRINT(N'-----------------------ĐÃ LẤY ĐƯỢC MÃ GIÁ SẢN PHẨM : '+@MANVL)

			IF LEN(@MANVL)>0 
				BEGIN
					INSERT INTO PHIEUNHAPKHO_DT(SOPHIEUNHAP, [DAY], RONG, CAO, SOBO, SOTHANH_BO, NOTE, 
												CREATED_AT, CREATED_BY, DEL_FLAG,DELAI,SAMPLEQTY,QTY,MANVL,
												QC_INSPECTOR,DONGIA_CTY,DONGIA_LOAI,NOTEHACAP,CODE,OVER_PLAN,CODENHOM,khacKho)
												VALUES(@SOPHIEU,@DAY,@RONG,@DAI,@SOBO,@SOTHANHBO,@NOTE,GETDATE(),@USERNAME,
												'N','N',0,0,@MANVL,'N',0,0,@NOTEHACAP,@CODE,@OVER,@CODENHOM,@KHACKHO)
					SELECT @RESULT = 1
					COMMIT
				END
			ELSE
				BEGIN
					SELECT @RESULT = 0
					ROLLBACK
				END
			
			SELECT @RESULT AS RESULT
END
GO
/****** Object:  StoredProcedure [nlg].[proc_add_nghiem_thu]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROC [nlg].[proc_add_nghiem_thu] 
	@IDDT AS INT,
	@SOTHANH AS INT,
	@CODE AS VARCHAR(40),
	@TYPEID AS INT,-- 
	@GAPDOI AS NCHAR(10),
	@NOTE AS NVARCHAR(400),
	@USERNAME AS VARCHAR(30)
	
AS
BEGIN 
	BEGIN TRANSACTION
		BEGIN TRY
			DECLARE @MANVL AS VARCHAR(50),
				@SOPHIEU AS VARCHAR(40),
				@VUNG AS NCHAR(10),
				@MANCC AS NCHAR(10),
				@DAY AS INT,
				@RONG AS INT,
				@DAI AS INT,
				@CPQTY AS INT,
				@TONGTHANHDAHC AS INT,
				@SOTHANHLAYMAU AS INT,
				@RESULT AS BIT,
				@MESSAGE AS NVARCHAR(200),
				@ISDOUBLETYPE AS INT ,
				@CODECP AS VARCHAR(40)
				
			-- LẤY MÃ TÍNH TIỀN
			SELECT @SOPHIEU = SOPHIEUNHAP,@SOTHANHLAYMAU=SAMPLEQTY*SOTHANH_BO FROM PHIEUNHAPKHO_DT WHERE ID = @IDDT
			SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU= @SOPHIEU
			SELECT @VUNG = VUNG FROM PROVIDERS WHERE CODE= @MANCC
				
			SELECT @DAY = [DAY],@RONG=RONG,@DAI=DAI FROM BOM WHERE TRIM(CODE)=TRIM(@CODE)
			SELECT @ISDOUBLETYPE =0 
			IF TRIM(@VUNG) = 'QT' 
				SELECT @MANVL = MANVL FROM nlgO WHERE MANVLKHO=TRIM(@CODE) AND SUBSTRING(TRIM(MANVL),0,3)='QT'
			ELSE
				SELECT @MANVL = MANVL FROM nlgO WHERE MANVLKHO=TRIM(@CODE) AND NOT SUBSTRING(TRIM(MANVL),0,3)='QT'
			-- KHÔNG CẦN LẤY GIÁ NỮA
			-- VÌ KHI LOAD BIÊN BẢN TỰ ĐỘNG LẤY LẠI GIÁ, HEHEH
			--SELECT @DONGIACTY = COST FROM BANGGIANVL WHERE TRIM(MASP)=TRIM(@MANVL) AND APPLY_DATE IS NOT NULL AND APPLY_DATE <= @NGAYNHAPKHO ORDER BY APPLY_DATE DESC
			
			

			
			

			--KIỂM TRA XEM XEM HẠ CẤP QUI CÁCH NÀY ĐÃ CÓ LOẠI HẠ CẤP NÀY HAY CHƯA
			-- NÊU ĐÃ CÓ RỒI THỲ KO CHO HẠ CẤP NỮA
			
			SELECT @ISDOUBLETYPE = COUNT(ID) FROM HACAP WHERE ID_DT=@IDDT AND [TYPE]=@TYPEID AND DEL_FLAG='N'
			IF @ISDOUBLETYPE>0
				BEGIN
					SELECT @RESULT = 0,@MESSAGE=N'LOẠI HẠ CẤP NÀY ĐÃ ĐƯỢC CHỌN RỒI !'
					ROLLBACK
				END
			ELSE
				BEGIN
					INSERT INTO HACAP (ID_DT,[TYPE],[DAY],[RONG],CAO,NOTE,DEL_FLAG,CREATED_AT,CREATED_BY,SOTHANH,MANVL,DONGIA_CTY,DONGIA_LOAI,GAPDOI,CODE)
										VALUES(@IDDT,@TYPEID,@DAY,@RONG,@DAI,@NOTE,'N',GETDATE(),@USERNAME,@SOTHANH,@MANVL,0,0,@GAPDOI,@CODE)
					-- CẬP NHẬT LẠI SỐ LƯỢNG ĐẠT YÊU CẦU HẠ CẤP CỦA CHÍNH PHẨM
					SELECT @TONGTHANHDAHC = SUM(SOTHANH) FROM HACAP WHERE ID_DT=@IDDT AND DEL_FLAG='N'
			
					--SỐ LƯỢNG ĐẠT CHÍNH PHẨM BẰNG SỐ THANH LẤY MẪU - TỔNG SỐ THANH BỊ HẠ CẤP RỒI
					SELECT @CPQTY = @SOTHANHLAYMAU-@TONGTHANHDAHC
					--NẾU SỐ LƯỢNG NHẬP HẠ CẤP < SỐ LƯỢNG LẤY MẪU VÀ ĐÃ HẠ CẤP RỒI THÌ OK
					IF @CPQTY>0
						BEGIN
							UPDATE PHIEUNHAPKHO_DT SET QTY = @CPQTY WHERE ID = @IDDT
							SELECT @RESULT = 1,@MESSAGE = N'Thành công !'
							COMMIT
						END
					ELSE 
						BEGIN
							SELECT @RESULT = 0,@MESSAGE=N'SỐ LƯỢNG NHẬP VÀO KHÔNG CHÍNH XÁC !'
							ROLLBACK
						END
				END
			
			
		END TRY
		BEGIN CATCH
			SELECT @RESULT = 0
			ROLLBACK
		END CATCH
		SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_add_pkndtl]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE     PROC [nlg].[proc_add_pkndtl] @iddt as int,@sobo as int,@result as bit output
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE @newSoBo as int,@remainM3 as float,@remainThanh as int,@klQuiCach as float,@NHOMCODE as INT,@sothanh as int,@sophieu as varchar(30)
			

		-- kiểm tra số thanh có thể nhập
		DECLARE @KH AS FLOAT,@TH AS FLOAT,@MANCC AS NCHAR(10),@ngaynhapkho as datetime,
				@KH_TONG AS FLOAT,@TH_TONG AS FLOAT,@VUOT_KH AS BIT,@MESSAGE AS NVARCHAR(100)
		
		-- UPDATE TRƯỚC CÁI ĐÃ
		SELECT @newSoBo = SOBO+@sobo FROM PHIEUNHAPKHO_DT WHERE ID=@iddt;
		INSERT INTO PNK_DTL(ID_DT,SOBO) VALUES(@iddt,@sobo);
		UPDATE PHIEUNHAPKHO_DT SET SOBO=@newSoBo WHERE ID=@iddt;


		SELECT @NHOMCODE = CODENHOM,@sophieu=SOPHIEUNHAP,@VUOT_KH =OVER_PLAN FROM PHIEUNHAPKHO_DT WHERE ID=@iddt
		SELECT @sothanh = @sobo*SOTHANH_BO  FROM PHIEUNHAPKHO_DT WHERE ID=@iddt
		SELECT @ngaynhapkho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
		SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
		--KIỂM TRA MÃ NHẬP KHO NÀY LÀ VƯỢT KẾ HOẠCH HAY KHÔNG
		-- NẾU LÀ VƯỢT KẾ HOẠC THỲ KIỂM TRA KẾ HOẠCH TỔNG, VÀ THỰC HIỆN TỔNG
		IF @VUOT_KH = 1
			BEGIN
				SELECT @KH_TONG = SUM(PL.PLANQTY)
				FROM PLAN_nlg  AS PL
				INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
				WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho)
				AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho) AND PL.GROUP_CODE=@NHOMCODE
				GROUP BY PL.GROUP_CODE
				--THỰC HIỆN TỔNG
				SELECT @TH_TONG = SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)))
				FROM PHIEUNHAPKHO_DT AS PT
				INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
				INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
				AND PT.DEL_FLAG='N'  AND DELAI='N' AND PT.CODENHOM=@NHOMCODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
				AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho)
				GROUP BY PT.CODENHOM

				IF @TH_TONG>=@KH_TONG 
					BEGIN
						SELECT @result =0,@MESSAGE =N'SỐ LƯỢNG VƯỢT QUÁ KẾ HOẠCH TỔNG !'
						ROLLBACK
					END
				ELSE
					BEGIN
						--CHO PHÉP NHẬP
						SELECT @result =1 ,@MESSAGE=N' NHẬP NGOÀI KH: -> THÀNH CÔNG !'
						COMMIT
					END
			END
		--NẾU NHẬP TRONG KẾ HOẠCH
		-- THÌ KIỂM TRA SỐ LƯỢNG THỰC HIỆN CỦA NHÀ CUNG CẤP
		-- VÀ KẾ HOẠCH CHO NHÀ CUNG CẤP
		ELSE
			BEGIN
				--CHECK KẾ HOẠCH NHÀ CUNG CẤP
				SELECT @KH = SUM(PL.PLANQTY)
				FROM PLAN_nlg  AS PL
				INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
				WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho)
				AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho) 
				AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@NHOMCODE
				GROUP BY PL.GROUP_CODE
				--CHECK THỰC HIỆN NHÀ CUNG CẤP
				SELECT @TH =ROUND(SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4)),4)
				FROM PHIEUNHAPKHO_DT AS PT
				INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
				INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
				AND PT.DEL_FLAG='N'  AND DELAI='N' AND PT.CODENHOM=@NHOMCODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
				AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho) AND PN.MANCC=@MANCC
				GROUP BY PT.CODENHOM
				--VALIDATE
				IF @TH >@KH 
					BEGIN
						SELECT @result=0,@MESSAGE=N'VƯỢT KẾ HOẠCH NHÀ CUNG CẤP, NẾU ĐỒNG Ý NHẬP NGOÀI HÃY THÊM MÃ MỚI !'
						ROLLBACK
					END
				ELSE
					BEGIN
						SELECT @result=1,@MESSAGE=N'NHẬP TRONG KH: -> THÀNH CÔNG !'
						COMMIT
					END
			END


		
		
		SELECT @result AS 'RESULT',@MESSAGE AS 'MESSAGE',@KH_TONG AS 'KH_TONG',@TH_TONG AS 'TH_TONG',@TH as 'TH',@KH AS 'KH'

END
GO
/****** Object:  StoredProcedure [nlg].[proc_change_plan_supplier_to_supplier]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [nlg].[proc_change_plan_supplier_to_supplier] @FROMSUPPLIER AS VARCHAR(20), @PLANQTY AS FLOAT,@TOSUPPLIER AS VARCHAR(30),@GROUP_CODE AS INT,
@USERNAME AS VARCHAR(50),@MONTH_OF_PLAN AS INT,@YEAR_PLAN AS INT
AS
BEGIN
	DECLARE @RESULT AS BIT,@MESSAGE AS NVARCHAR(100),@KH_NCC AS FLOAT,@TH_NCC AS FLOAT, @KH_TONG AS FLOAT, @TH_TONG AS FLOAT,@REMAIN AS FLOAT,@toUsername as varchar(40),@STAFF AS VARCHAR(40)

	----KẾ HOẠCH TỔNG
	--SELECT @KH_TONG = SUM(PLANQTY) FROM PLAN_nlg WHERE DEL_FLAG='N' AND GROUP_CODE=@GROUP_CODE AND DATEPART(MONTH,CREATED_AT) =@MONTH_OF_PLAN 
	--AND DATEPART(YEAR,CREATED_AT)=@YEAR_PLAN
	---- THỰC HIỆN TỔNG
	--SELECT @TH_TONG = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
	--	FROM PHIEUNHAPKHO_DT AS PT
	--	INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
	--	WHERE  CODENHOM = @GROUP_CODE AND DATEPART(MONTH,PN.CREATED_AT)=@MONTH_OF_PLAN
	--	AND DATEPART(YEAR,PN.CREATED_AT) =@YEAR_PLAN
	--	AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N';

	SELECT @KH_NCC =  SUM(PLANQTY) FROM PLAN_nlg WHERE DEL_FLAG='N' AND GROUP_CODE=@GROUP_CODE AND DATEPART(MONTH,CREATED_AT) =@MONTH_OF_PLAN 
	AND DATEPART(YEAR,CREATED_AT)=@YEAR_PLAN AND MANCC=@FROMSUPPLIER

	  DECLARE @NHOMKHO AS nchar(10)

	 SELECT @NHOMKHO = KHO FROM PLAN_nlg WHERE GROUP_CODE = @GROUP_CODE  AND MANCC = @FROMSUPPLIER AND DATEPART(MONTH,CREATED_AT) = @MONTH_OF_PLAN
	AND DATEPART(YEAR,CREATED_AT)=@YEAR_PLAN AND KHO is not null

	--THỰC HIỆN CHO NHÀ CUNG CẤP
	SELECT @TH_NCC = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @GROUP_CODE AND DATEPART(MONTH,PN.CREATED_AT)=@MONTH_OF_PLAN
		AND DATEPART(YEAR,PN.CREATED_AT) =@YEAR_PLAN
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N' AND PN.MANCC=@FROMSUPPLIER;


	IF @KH_NCC IS NULL SELECT @KH_NCC =0
	IF @TH_NCC IS NULL SELECT @TH_NCC = 0
	--NẾU THỰC HIỆN CỦA NHÀ CUNG CẤP ĐÃ VƯỢT QUÁ KẾ HOẠCH NHÀ CUNG CẤP
	-- THỲ KHÔNG THỂ CHUYỂN KÊ HOẠCH
	IF @TH_NCC >= @KH_NCC
		BEGIN
			SELECT @RESULT =0, @MESSAGE=N'THỰC HIỆN NHÀ CUNG CẤP ĐÃ LỚN HƠN KẾ HOẠCH NHÀ CUNG CẤP !'
		END
	ELSE 
	--NGƯỢC LẠI
	--NẾU THỰC HIỆN NHÀ CUNG CẤP NHỎ HƠN KH NHÀ CUNG CẤP
	-- THỲ CHECK SỐ M3 CÒN LẠI ĐC PHÉP CHUYỂN
		BEGIN
			SELECT @REMAIN = @KH_NCC-@TH_NCC
			--NẾU SỐ LƯỢNG NHẬP VÀO LỚN HƠN SỐ LƯỢNG CÒN LẠI
			-- THỲ BÁO FAIL KÈM SỐ LƯỢNG TỐI ĐA CÒN LẠI

			IF @PLANQTY >@REMAIN
			BEGIN
				SELECT @RESULT=0,@MESSAGE=N'SỐ LƯỢNG CHUYỂN LỚN HƠN SỐ LƯỢNG TỐI ĐA CHO PHÉP ( '+CONVERT(varchar(40),@REMAIN)+'m³)'
			END
			ELSE	
				BEGIN
					--KIỂM TRA TÊN NGƯỜI LẬP KẾ HOẠCH
					SELECT @STAFF = STAFF FROM PROVIDERS WHERE CODE=@TOSUPPLIER
					--NẾU 2 NHÀ CUNG CẤP KHÁC NHẬN VIÊN KẾ HOẠCH
					-- THỲ ĐỔI NHÂN VIÊN KẾ HOẠCH THÀNH NHÂN VIÊN KẾ HOẠCH THEO ĐÚNG NHÀ CUNG CẤP
					IF TRIM(@STAFF) =TRIM(@USERNAME)
						SELECT @toUsername = @USERNAME
					ELSE
						SELECT @toUsername = @STAFF
					BEGIN TRANSACTION
					BEGIN TRY
						INSERT INTO PLAN_nlg(MANCC,PLANQTY,DEL_FLAG,CREATE_BY,CREATED_AT,GROUP_CODE,NOTE,KHO) 
						VALUES(@FROMSUPPLIER,(@PLANQTY*-1),'N',@USERNAME,GETDATE(),@GROUP_CODE,N'CHUYỂN KẾ HOẠCH CHO NHÀ CUNG CẤP : '+@TOSUPPLIER, @NHOMKHO)

						INSERT INTO PLAN_nlg(MANCC,PLANQTY,DEL_FLAG,CREATE_BY,CREATED_AT,GROUP_CODE,NOTE,KHO) 
						VALUES(@TOSUPPLIER,@PLANQTY,'N',@toUsername,GETDATE(),@GROUP_CODE,N'NHẬN KẾ HOẠCH TỪ NHÀ CUNG CẤP :'+@FROMSUPPLIER, @NHOMKHO)
						SELECT @RESULT =1, @MESSAGE=N'CHUYỂN KẾ HOẠCH THÀNH CÔNG !'
						COMMIT
					END TRY
					BEGIN CATCH
						SELECT @RESULT =0,@MESSAGE =N'LỖI : '+ ERROR_MESSAGE()
						ROLLBACK
					END CATCH
				END
		END
	
	SELECT @RESULT AS RESULT, @MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_change_qty_PNK_DTL]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [nlg].[proc_change_qty_PNK_DTL]  @ID AS INT, @NEWSOBO AS INT
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE @OVER_PLAN AS BIT,@IDDT AS INT,@KH_TONG AS FLOAT,@TH_TONG AS FLOAT,@KH_NCC  AS FLOAT, @TH_NCC AS FLOAT,@ID_DT AS INT,
	@ngaynhapkho AS DATETIME,@CODENHOM AS INT,@MANCC AS NCHAR(10),@SOPHIEU AS VARCHAR(40),@RESULT AS BIT, @MESSAGE AS NVARCHAR(100)
	UPDATE PNK_DTL SET SOBO =@NEWSOBO WHERE ID=@ID
	SELECT @ID_DT = ID_DT FROM PNK_DTL WHERE ID =@ID
	UPDATE PHIEUNHAPKHO_DT SET SOBO=(SELECT SUM(SOBO) FROM PNK_DTL WHERE ID_DT=@ID_DT) WHERE ID=@ID_DT

	--KIỂM TRA SAU KHI UPDATE

	--KIỂM TRA XEM MÃ NHẬP KHO LÀ NHẬP TRONG KẾ HOACH HAY NGOÀI KẾ HOẠCH
	SELECT @IDDT = ID_DT FROM PNK_DTL WHERE ID = @ID
	SELECT @OVER_PLAN = OVER_PLAN,@SOPHIEU  = SOPHIEUNHAP,@CODENHOM = CODENHOM  FROM PHIEUNHAPKHO_DT WHERE ID = @IDDT
	--LẤY THÔNG TIN SỐ PHIẾU, NHÀ CUNG CẤP, NGÀY NHẬP KHO
	SELECT @ngaynhapkho = CREATED_AT,@MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@SOPHIEU

	-- NẾU MÃ NHẬP KHO ĐANG LÀ NHẬP NGOÀI KÊ HOẠCH 
	-- THỲ KIỂM TRA KẾ HOẠCH TỔNG VÀ THỰC HIỆN TỔNG
	SELECT @KH_TONG = SUM(PL.PLANQTY)
	FROM PLAN_nlg  AS PL
	INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
	WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) AND 
	DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho) AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODENHOM
	GROUP BY PL.GROUP_CODE
	-- THỰC HIỆN TỔNG TRONG THÁNG
	SELECT @TH_TONG =SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)))
	FROM PHIEUNHAPKHO_DT AS PT
	INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
	INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
	AND PT.DEL_FLAG='N' AND DELAI='N' AND PT.CODENHOM=@CODENHOM AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
	AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho)
	GROUP BY PT.CODENHOM

	IF @KH_TONG IS NULL SELECT @KH_TONG =0
	IF @TH_TONG IS NULL SELECT @TH_TONG = 0

	-- NẾU KHÔNG CÓ KẾ HOẠCH TỔNG BÁO FAIL LUÔN
	-- TRONG MỌI TRƯỜNG HỢP
	IF @KH_TONG=0 
		BEGIN
			SELECT @RESULT =0, @MESSAGE=N' KHÔNG CÓ KẾ HOẠCH TỔNG THỂ !'
			ROLLBACK
		END
	ELSE
		BEGIN
			-- NẾU MÃ NHẬP KHO ĐANG NHẬP LÀ VƯỢT KẾ HOẠCH
			-- THỲ CHECK KẾ HOẠCH VÀ THỰC HIỆN TỔNG
			IF @OVER_PLAN = 1
				BEGIN 
					IF  @TH_TONG >@KH_TONG
						BEGIN
							SELECT @RESULT =0, @MESSAGE=N' SỐ LƯỢNG VƯỢT QUÁ KẾ HOẠCH TỔNG !'
							ROLLBACK
						END
					ELSE 
						BEGIN
							SELECT @RESULT =1, @MESSAGE=N'NHẬP NGOÀI KẾ HOẠCH: -> THÀNH CÔNG !'
							COMMIT
						END
				END
			-- NGƯỢC LẠI
			-- NẾU MÃ ĐANG NHẬP LÀ NHẬP TRONG KẾ HOẠCH NHÀ CUNG CẤP
			-- THỲ KIÊM TRA KẾ HOẠCH VÀ THỰC HIỆN CỦA NHÀ CUNG CẤP
			-- NẾU VƯỢT QUÁ BÁO FAIL
			ELSE
				BEGIN
					SELECT @KH_NCC = SUM(PL.PLANQTY)
					FROM PLAN_nlg  AS PL
					INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
					WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho)
					AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
					AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODENHOM
					GROUP BY PL.GROUP_CODE

					SELECT @TH_NCC = SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)))
					FROM PHIEUNHAPKHO_DT AS PT
					INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.MANCC=@MANCC AND PN.DEL_FLAG='N'
					INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
					AND PT.DEL_FLAG='N'  AND DELAI='N' AND PT.CODENHOM=@CODENHOM AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
					AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho)
					GROUP BY PT.CODENHOM

					IF @TH_NCC IS NULL SELECT @TH_NCC =0
					IF @KH_NCC IS NULL SELECT @KH_NCC = -1

					-- NẾU THỰC HIỆN NHÀ CUNG CẤP LỚN HƠN KẾ HOẠCH NHÀ CUNG CẤP THỲ BÁO FAIL
					-- BÁO NHẬP NGOÀI KẾ HOẠCH
					IF @TH_NCC>@KH_NCC
						BEGIN
							SELECT @RESULT = 0, @MESSAGE =N' KHÔNG CÓ KẾ HOẠCH NHÀ CUNG CẤP  HOẶC ĐÃ NHẬP VƯỢT KH NCC! HÃY NHẬP MÃ KHÁC NGOÀI KẾ HOẠCH'
							ROLLBACK
						END
					ELSE
						BEGIN
							SELECT @RESULT = 1, @MESSAGE =N'Thành công !'
							COMMIT
						END

				END

		END
		SELECT @RESULT AS [RESULT], @MESSAGE AS [MESSAGE],@TH_NCC as [THNCC],@KH_NCC AS [KHNCC]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_change_sample_bo]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [nlg].[proc_change_sample_bo] @IDDT AS INT,@NEWSAMPLE AS INT
AS
BEGIN

	BEGIN TRANSACTION
	DECLARE @TONGHACAP AS INT,@SOTHANHLAYMAU AS INT,@RESULT AS BIT,@MESSAGE AS NVARCHAR(100),@SOTHANHBO AS INT
	
	
	SELECT @SOTHANHLAYMAU = SAMPLEQTY*SOTHANH_BO ,@SOTHANHBO =SOTHANH_BO FROM PHIEUNHAPKHO_DT WHERE ID=@IDDT
	SELECT @TONGHACAP = SUM(SOTHANH) FROM HACAP WHERE ID_DT=@IDDT AND DEL_FLAG='N'
	--NẾU TỔNG SỐ LƯỢNG ĐÃ HẠ CẤP MÀ LỚN HƠN SỐ BÓ LẤY MẪU * SO THANH /BÓ
	-- THỲ ROLLBACK, BÁO FAIL
	IF @TONGHACAP > @NEWSAMPLE*@SOTHANHBO
		BEGIN
			SELECT @RESULT = 0 , @MESSAGE = N'SỐ LƯỢNG LẤY MẪU KHÔNG THỂ NHỎ HƠN TỔNG SỐ THANH '
			ROLLBACK
		END
	ELSE 
		BEGIN
			UPDATE PHIEUNHAPKHO_DT SET SAMPLEQTY= @NEWSAMPLE,QTY = @NEWSAMPLE*SOTHANH_BO-@TONGHACAP WHERE ID =@IDDT
			SELECT @RESULT = 1 , @MESSAGE = N'THÀNH CÔNG !'
			COMMIT
		END
		SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_check_remain_input_wh]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROC [nlg].[proc_check_remain_input_wh] @CODE AS VARCHAR(30),@sophieu AS varchar(40)
AS
DECLARE @KH AS FLOAT, @KH2 AS FLOAT,@THNCC AS FLOAT,@MANCC AS NCHAR(10),@MAKHO AS NCHAR(10),@ngaynhapkho as datetime,@KH_TONG_THE AS FLOAT,@TH_TONG_THE AS FLOAT, @DM_KHO AS FLOAT,@TH_THEO_KHO AS FLOAT 

SELECT @ngaynhapkho = CREATED_AT, @MANCC = MANCC, @MAKHO = MAKHO FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
DECLARE @THUOCKHO as nchar(10)
SELECT TOP 1 @THUOCKHO = PL.KHO
FROM PLAN_nlg PL
WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
--select @THUOCKHO

--Select * from PLAN_nlg
--lấy kế hoạch tổng thể và thực hiện tổng thế
--SELECT @KH_TONG_THE = SUM(PLANQTY) FROM PLAN_nlg 
--	WHERE DATEPART(MONTH,CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) AND DATEPART(YEAR,CREATED_AT)=DATEPART(YEAR,@ngaynhapkho) AND DEL_FLAG='N' AND GROUP_CODE=@CODE
--IF @KH_TONG_THE IS NULL SELECT @KH_TONG_THE=0


-- 2020-05-14 
-- trong hay ngoài kế hoạch không phụ thuộc vào kế hoạch tổng nữa
select @KH_TONG_THE=9999
IF @KH_TONG_THE >0 
	BEGIN
		--KẾ HOẠCH THEO NHÀ CUNG CẤP
		SELECT @KH = SUM(PL.PLANQTY)
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
		GROUP BY PL.GROUP_CODE;

		--KẾ HOẠCH THEO NHÀ CUNG CẤP
		SELECT @KH2 = (SUM(PL.PLANQTY) + (0.05*SUM(PL.PLANQTY)))
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
		and PL.KHO IN (select NhomKHo from NhomKho Where Makho = @MAKHO)
		--GROUP BY PL.GROUP_CODE;
		
		--THỰC HIỆN  THEO NHÀ CUNG CẤP
		SELECT @THNCC = ROUND(SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4)),4)
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE TRIM(PN.MANCC)=@MANCC AND  CODENHOM = @CODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PN.CREATED_AT) =DATEPART(YEAR,@ngaynhapkho)
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N' 

		PRINT(N'THỰC HIỆN THEO NHÀ CUNG CẤP :'+CONVERT(VARCHAR(40),@THNCC))
		SELECT @DM_KHO = SUM(PLANQTY)*1.2
		FROM DINH_MUC_KHO 
		WHERE  GROUP_CODE = @CODE and MAKHO = @MAKHO AND DATEPART(MONTH,CREATED_AT)=DATEPART(MONTH, GETDATE()) and DATEPART(YEAR,CREATED_AT) = DATEPART(YEAR, GETDATE())
		SELECT @TH_THEO_KHO = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @CODE and PN.MAKHO = @MAKHO AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH, GETDATE()) and DATEPART(YEAR,PN.CREATED_AT) = DATEPART(YEAR, GETDATE()) and PT.DEL_FLAG = 'N' and PN.DEL_FLAG = 'N' and PT.DELAI = 'N'
		----THỰC HIỆN TỔNG THỂ
		SELECT @TH_TONG_THE = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @CODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PN.CREATED_AT) =DATEPART(YEAR,@ngaynhapkho)
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N';
		PRINT(N'THỰC HIỆN TỔNG THỂ : '+CONVERT(VARCHAR(40),@TH_TONG_THE))

		
	END
-- KHÔNG CÓ KẾ HOẠCH TỔNG THỂ THỲ ĐUỔI VỀ
ELSE
	SELECT @KH_TONG_THE = 0, @KH=0,@THNCC = 0, @KH2 = 0, @TH_THEO_KHO = 0
IF @THNCC IS NULL SELECT @THNCC = 0

IF @KH 
	IS NULL SELECT @KH =0
ELSE
	SELECT @KH = @KH +(0.05*@KH)
IF @TH_TONG_THE IS NULL SELECT @TH_TONG_THE=0

IF (@KH2 
	IS NULL OR (@KH2 -@THNCC) < 0) SELECT @KH2 =0

--IF @THUOCKHO 
--	IS NOT NULL SELECT @THUOCKHO = @MAKHO



-- 24-03-2020
-- NHẬP THEO KẾ HOẠCH NGOẠI LỆ
-- NẾU CÓ KẾ HOẠCH NHẬP NGOẠI LỆ CHO NHÀ CUNG CẤP THÌ KIỂM TRA 
-- VÀ CỘNG THÊM VÀO KẾ HOẠCH TỔNG CỦA THÁNG NẾU CÓ
-- VÀ SỐ LƯỢNG NHẠP NÀY SẼ COI NHƯ LÀ NHẬP NGOÀI KẾ HOẠCH 
-- VÀ BỊ TRỪ TIỀN THEO QUI ĐỊNH
IF  EXISTS (SELECT * FROM PLAN_EXCEPTION WHERE  MANCC = TRIM(@MANCC) AND GROUP_QUICACH_ID = @CODE AND EXPR_DATE > @ngaynhapkho) 
	SELECT @KH_TONG_THE = @KH_TONG_THE + SUM(KHOILUONG) FROM PLAN_EXCEPTION WHERE MANCC = TRIM(@MANCC) AND GROUP_QUICACH_ID = @CODE AND EXPR_DATE > @ngaynhapkho GROUP BY MANCC,GROUP_QUICACH_ID


SELECT @THUOCKHO as [kho], @KH AS [KH],@KH2 AS [KH2],@THNCC AS [TH],ROUND(@KH-@THNCC,2) AS [REMAIN], @KH2 AS [REMAIN2],@KH_TONG_THE AS [KHTONGTHE],@TH_TONG_THE AS [TH_TONG], @TH_THEO_KHO AS [TH_KHO],@DM_KHO AS [DM_KHO]


GO
/****** Object:  StoredProcedure [nlg].[proc_check_remain_input_wh_0000]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE         PROC [nlg].[proc_check_remain_input_wh_0000] @CODE AS VARCHAR(30),@sophieu AS varchar(40)
AS
DECLARE @KH AS FLOAT,@THNCC AS FLOAT,@MANCC AS NCHAR(10),@ngaynhapkho as datetime
,@KH_TONG_THE AS FLOAT,@TH_TONG_THE AS FLOAT,@DATESTRINGFROM VARCHAR(200),@DATESTRINGTO VARCHAR(200)
SELECT @ngaynhapkho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
SELECT @DATESTRINGTO = CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho))+ CASE WHEN DATEPART(MONTH,@ngaynhapkho)>=10 THEN '' ELSE '0' END + CONVERT(VARCHAR(200),DATEPART(MONTH,@ngaynhapkho)))
IF DATEPART(MONTH,@ngaynhapkho) > 1
	SELECT @DATESTRINGFROM = CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho))+ CASE WHEN DATEPART(MONTH,@ngaynhapkho)>=10 THEN '' ELSE '0' END + CONVERT(VARCHAR(200),DATEPART(MONTH,@ngaynhapkho)))
ELSE 
	SELECT @DATESTRINGFROM = CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho)-1)+ '12')
--lấy kế hoạch tổng thể và thực hiện tổng thế
SELECT @KH_TONG_THE = SUM(PLANQTY) FROM PLAN_nlg 
	WHERE 
	CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,CREATED_AT))+
	CASE WHEN DATEPART(MONTH,CREATED_AT)>=10 THEN '' ELSE '0' END
	+CONVERT(VARCHAR(200),DATEPART(MONTH,CREATED_AT)))
	 BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
	 AND DEL_FLAG='N' AND GROUP_CODE=@CODE
IF @KH_TONG_THE IS NULL SELECT @KH_TONG_THE=0
IF @KH_TONG_THE >0 
	BEGIN
		--KẾ HOẠCH THEO NHÀ CUNG CẤP
		SELECT @KH = SUM(PL.PLANQTY)
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		WHERE PL.DEL_FLAG='N' AND 
		CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,PL.CREATED_AT))+
		CASE WHEN DATEPART(MONTH,PL.CREATED_AT)>=10 THEN '' ELSE '0' END
		+CONVERT(VARCHAR(200),DATEPART(MONTH,PL.CREATED_AT)))
		BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
		GROUP BY PL.GROUP_CODE;
		PRINT(CONVERT(VARCHAR(40),@KH))
		
		--THỰC HIỆN  THEO NHÀ CUNG CẤP
		SELECT @THNCC = ROUND(SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4)),4)
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE TRIM(PN.MANCC)=@MANCC AND  CODENHOM = @CODE AND 
		CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,PT.CREATED_AT))+
		CASE WHEN DATEPART(MONTH,PT.CREATED_AT)>=10 THEN '' ELSE '0' END
		+CONVERT(VARCHAR(200),DATEPART(MONTH,PT.CREATED_AT)))
		 BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N' 

		PRINT(N'THỰC HIỆN THEO NHÀ CUNG CẤP :'+CONVERT(VARCHAR(40),@THNCC))
		
		----THỰC HIỆN TỔNG THỂ
		SELECT @TH_TONG_THE = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @CODE AND 
		CONVERT(INT,CONVERT(VARCHAR(200),DATEPART(YEAR,PT.CREATED_AT))+
		CASE WHEN DATEPART(MONTH,PT.CREATED_AT)>=10 THEN '' ELSE '0' END
		+CONVERT(VARCHAR(200),DATEPART(MONTH,PT.CREATED_AT)))  BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N';
		PRINT(N'THỰC HIỆN TỔNG THỂ : '+CONVERT(VARCHAR(40),@TH_TONG_THE))

		
	END
-- KHÔNG CÓ KẾ HOẠCH TỔNG THỂ THỲ ĐUỔI VỀ
ELSE
	SELECT @KH_TONG_THE = 0, @KH=0,@THNCC = 0
IF @THNCC IS NULL SELECT @THNCC = 0
IF @KH IS NULL SELECT @KH =0
IF @TH_TONG_THE IS NULL SELECT @TH_TONG_THE=0


SELECT @KH AS [KH],@THNCC AS [TH],ROUND(@KH-@THNCC,2) AS [REMAIN],@KH_TONG_THE AS [KHTONGTHE],@TH_TONG_THE AS [TH_TONG]


GO
/****** Object:  StoredProcedure [nlg].[proc_check_remain_input_wh_2_MONTH]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE       PROC [nlg].[proc_check_remain_input_wh_2_MONTH] @CODE AS VARCHAR(30),@sophieu AS varchar(40)
AS
DECLARE @KH AS FLOAT,@THNCC AS FLOAT,@MANCC AS NCHAR(10),@ngaynhapkho as datetime
,@KH_TONG_THE AS FLOAT,@TH_TONG_THE AS FLOAT,@DATESTRINGFROM VARCHAR(200),@DATESTRINGTO VARCHAR(200)
SELECT @ngaynhapkho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
SELECT @DATESTRINGTO = CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho))+CONVERT(VARCHAR(200),DATEPART(MONTH,@ngaynhapkho))
IF DATEPART(MONTH,@ngaynhapkho)=1
	SELECT @DATESTRINGFROM = CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho))+CONVERT(VARCHAR(200),DATEPART(MONTH,@ngaynhapkho))
ELSE 
	SELECT @DATESTRINGFROM = CONVERT(VARCHAR(200),DATEPART(YEAR,@ngaynhapkho)-1)+CONVERT(VARCHAR(200),DATEPART(MONTH,@ngaynhapkho)-1)
--lấy kế hoạch tổng thể và thực hiện tổng thế
SELECT @KH_TONG_THE = SUM(PLANQTY) FROM PLAN_nlg 
	WHERE CONVERT(VARCHAR(200),DATEPART(YEAR,CREATED_AT))+CONVERT(VARCHAR(200),DATEPART(MONTH,CREATED_AT)) BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
	 AND DEL_FLAG='N' AND GROUP_CODE=@CODE
IF @KH_TONG_THE IS NULL SELECT @KH_TONG_THE=0
IF @KH_TONG_THE >0 
	BEGIN
		--KẾ HOẠCH THEO NHÀ CUNG CẤP
		SELECT @KH = SUM(PL.PLANQTY)
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		WHERE PL.DEL_FLAG='N' AND CONVERT(VARCHAR(200),DATEPART(YEAR,PL.CREATED_AT))+CONVERT(VARCHAR(200),DATEPART(MONTH,PL.CREATED_AT)) BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
		GROUP BY PL.GROUP_CODE;
		PRINT(CONVERT(VARCHAR(40),@KH))
		
		--THỰC HIỆN  THEO NHÀ CUNG CẤP
		SELECT @THNCC = ROUND(SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4)),4)
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE TRIM(PN.MANCC)=@MANCC AND  CODENHOM = @CODE AND 
		CONVERT(VARCHAR(200),DATEPART(YEAR,PT.CREATED_AT))+CONVERT(VARCHAR(200),DATEPART(MONTH,PT.CREATED_AT)) BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N' 

		PRINT(N'THỰC HIỆN THEO NHÀ CUNG CẤP :'+CONVERT(VARCHAR(40),@THNCC))
		
		----THỰC HIỆN TỔNG THỂ
		SELECT @TH_TONG_THE = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @CODE AND 
		CONVERT(VARCHAR(200),DATEPART(YEAR,PT.CREATED_AT))+CONVERT(VARCHAR(200),DATEPART(MONTH,PT.CREATED_AT)) BETWEEN @DATESTRINGFROM AND @DATESTRINGTO
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N';
		PRINT(N'THỰC HIỆN TỔNG THỂ : '+CONVERT(VARCHAR(40),@TH_TONG_THE))

		
	END
-- KHÔNG CÓ KẾ HOẠCH TỔNG THỂ THỲ ĐUỔI VỀ
ELSE
	SELECT @KH_TONG_THE = 0, @KH=0,@THNCC = 0
IF @THNCC IS NULL SELECT @THNCC = 0
IF @KH IS NULL SELECT @KH =0
IF @TH_TONG_THE IS NULL SELECT @TH_TONG_THE=0


SELECT @KH AS [KH],@THNCC AS [TH],ROUND(@KH-@THNCC,2) AS [REMAIN],@KH_TONG_THE AS [KHTONGTHE],@TH_TONG_THE AS [TH_TONG]


GO
/****** Object:  StoredProcedure [nlg].[proc_check_remain_input_wh_BAK_24_03_2020]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROC [nlg].[proc_check_remain_input_wh_BAK_24_03_2020] @CODE AS VARCHAR(30),@sophieu AS varchar(40)
AS
DECLARE @KH AS FLOAT,@THNCC AS FLOAT,@MANCC AS NCHAR(10),@ngaynhapkho as datetime,@KH_TONG_THE AS FLOAT,@TH_TONG_THE AS FLOAT
SELECT @ngaynhapkho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu

--lấy kế hoạch tổng thể và thực hiện tổng thế
SELECT @KH_TONG_THE = SUM(PLANQTY) FROM PLAN_nlg 
	WHERE DATEPART(MONTH,CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) AND DATEPART(YEAR,CREATED_AT)=DATEPART(YEAR,@ngaynhapkho) AND DEL_FLAG='N' AND GROUP_CODE=@CODE
IF @KH_TONG_THE IS NULL SELECT @KH_TONG_THE=0
IF @KH_TONG_THE >0 
	BEGIN
		--KẾ HOẠCH THEO NHÀ CUNG CẤP
		SELECT @KH = SUM(PL.PLANQTY)
		FROM PLAN_nlg  AS PL
		INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
		WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
		AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODE
		GROUP BY PL.GROUP_CODE;
		PRINT(CONVERT(VARCHAR(40),@KH))
		
		--THỰC HIỆN  THEO NHÀ CUNG CẤP
		SELECT @THNCC = ROUND(SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4)),4)
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE TRIM(PN.MANCC)=@MANCC AND  CODENHOM = @CODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PN.CREATED_AT) =DATEPART(YEAR,@ngaynhapkho)
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N' 

		PRINT(N'THỰC HIỆN THEO NHÀ CUNG CẤP :'+CONVERT(VARCHAR(40),@THNCC))
		
		----THỰC HIỆN TỔNG THỂ
		SELECT @TH_TONG_THE = SUM(ROUND((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO),4))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU=PT.SOPHIEUNHAP 
		WHERE  CODENHOM = @CODE AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho) 
		AND DATEPART(YEAR,PN.CREATED_AT) =DATEPART(YEAR,@ngaynhapkho)
		AND PN.DEL_FLAG='N' AND PT.DEL_FLAG='N' AND PT.DELAI='N';
		PRINT(N'THỰC HIỆN TỔNG THỂ : '+CONVERT(VARCHAR(40),@TH_TONG_THE))

		
	END
-- KHÔNG CÓ KẾ HOẠCH TỔNG THỂ THỲ ĐUỔI VỀ
ELSE
	SELECT @KH_TONG_THE = 0, @KH=0,@THNCC = 0
IF @THNCC IS NULL SELECT @THNCC = 0
IF @KH IS NULL SELECT @KH =0
IF @TH_TONG_THE IS NULL SELECT @TH_TONG_THE=0


SELECT @KH AS [KH],@THNCC AS [TH],ROUND(@KH-@THNCC,2) AS [REMAIN],@KH_TONG_THE AS [KHTONGTHE],@TH_TONG_THE AS [TH_TONG]


GO
/****** Object:  StoredProcedure [nlg].[proc_delete_nghiem_thu]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [nlg].[proc_delete_nghiem_thu] @ID AS INT
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE  @TONGHACAP AS INT,@IDDT AS INT,@SOTHANHLAYMAU AS INT,@RESULT AS BIT,@MESSAGE AS NVARCHAR(100)
	BEGIN TRY
		UPDATE HACAP SET DEL_FLAG='Y' WHERE ID=@ID
	
		SELECT @IDDT = ID_DT FROM HACAP WHERE ID=@ID
		SELECT @SOTHANHLAYMAU = SAMPLEQTY*SOTHANH_BO  FROM PHIEUNHAPKHO_DT WHERE ID=@IDDT
		SELECT @TONGHACAP = SUM(SOTHANH) FROM HACAP WHERE ID_DT=@IDDT AND DEL_FLAG='N'
		--CÂP NHẬT LẠI
		UPDATE PHIEUNHAPKHO_DT SET QTY = @SOTHANHLAYMAU-@TONGHACAP WHERE ID=@IDDT
		SELECT @RESULT =1,@MESSAGE=N'THÀNH CÔNG !'
		COMMIT
	END TRY
	BEGIN CATCH
		SELECT @RESULT=0,@MESSAGE=ERROR_MESSAGE()
		ROLLBACK
	END CATCH
	SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]

END
GO
/****** Object:  StoredProcedure [nlg].[proc_Reset_Gia_theo_So_phieu_V3]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROC [nlg].[proc_Reset_Gia_theo_So_phieu_V3]
    @SOPHIEU AS VARCHAR(30),
    @value bit output
AS
DECLARE @LoopCounter INT,@MaxID INT, @Code as VARCHAR(30),@DonGia INT,@MaSP varchar(30),@Vung varchar(30),
		@NgayApdung date,@NoteHaCap nchar(10),@loaiHaCap as int,@DonGiaHC INT,@khacKho as bit,@isOver as bit,@coc as nchar(10)
		,@rate as float,@rateUp as float,@rateDown as float,@hesoTruTheoTyLeDuoi as int,@hesoTruTheoTyLeTren as int,
		@sum_kl as float,@sum_kl_qc as float,@sum_khackho as float,@tlkhackho as float
		 --SELECT @NgayApdung = CONVERT(DATE,GETDATE())   -- LAAYS NHAM NGAY
		  SELECT @NgayApdung = CREATED_AT
FROM PHIEUNHAPKHO
WHERE SOPHIEU=@SOPHIEU 
		 --LẤY THÔNG TIN VÙNG CỦA BIÊN BẢN
		 SELECT @Vung = VUNG, @coc= COC
FROM PROVIDERS
WHERE CODE = (SELECT MANCC
FROM PHIEUNHAPKHO
WHERE SOPHIEU=@SOPHIEU AND DEL_FLAG='N' )
		 --LẤY THÔNG TIN LOOPID CHO BẢNG CHI TIẾT PHIẾU NHẬP KHO
		 SELECT @LoopCounter = min(ID), @MaxID = max(ID)
FROM PHIEUNHAPKHO_DT
WHERE SOPHIEUNHAP=@SOPHIEU AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
		 -- LẤY THÔNG TIN TỶ LỆ CHÍNH PHẨM CỦA BIÊN BẢN
		 

		SELECT @sum_kl = ROUND(SUM(i.KL_KHO),4) , @sum_kl_qc = ROUND(SUM(i.KL_QC),4)
FROM
    (SELECT ROUND((PT.SOTHANH_BO * PT.SAMPLEQTY - (
			SELECT SUM(CAST(SOTHANH AS float))
        FROM HACAP
        WHERE ID_DT=PT.ID AND DEL_FLAG='N'
        GROUP BY ID_DT
			)) /(PT.SAMPLEQTY*PT.SOTHANH_BO) ,4 ) AS 'TYLE',
        ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO),4) AS 'KL_KHO',
        (PT.SOTHANH_BO * PT.SAMPLEQTY - (
			SELECT SUM(CAST(SOTHANH AS float))
        FROM HACAP
        WHERE ID_DT=PT.ID AND DEL_FLAG='N'
        GROUP BY ID_DT
			)) /(PT.SAMPLEQTY*PT.SOTHANH_BO) *
			(PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO) AS 'KL_QC'
    FROM PHIEUNHAPKHO_DT AS PT
        INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
        INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
    WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND PT.SOPHIEUNHAP IN (
			SELECT SOPHIEU
        FROM PHIEUNHAPKHO
        WHERE   ALLOWMODIFY='N')
        AND PT.NOTEHACAP ='0' AND SOPHIEUNHAP=TRIM(@SOPHIEU)) AS i
		
		SELECT @sum_khackho = ROUND(SUM(k.KL_KHACKHO),4)
		FROM (SELECT (ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO),4)) AS 'KL_KHACKHO'
		FROM PHIEUNHAPKHO_DT AS PT
		
		WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND khacKho = 1 
		 AND PT.NOTEHACAP ='0' AND SOPHIEUNHAP=TRIM(@SOPHIEU)) AS k
		
		SELECT @tlkhackho = ROUND(@sum_khackho/@sum_kl,4)
		
		SELECT @rate = ROUND(@sum_kl_qc/@sum_kl,4)
		PRINT(CONVERT(varchar(30),@rate))
		---- LẤY TỶ LỆ MỐC TRÊN VÀ TỶ LỆ MỐC DƯỚI
		SELECT TOP 1
    @rateDown = TYLE, @hesoTruTheoTyLeDuoi=HESO
FROM CONFIG_TYLE
WHERE TRIM([TYPE])='DOWN'
		SELECT TOP 1
    @rateUp = TYLE, @hesoTruTheoTyLeTren=HESO
FROM CONFIG_TYLE
WHERE TRIM([TYPE])='UP'
		--kiểm tra điều kiện
		

 WHILE(@LoopCounter IS NOT NULL AND @LoopCounter <= @MaxID)

 BEGIN
    -- LẤY MÃ SP NẾU CÓ
    SELECT @Code = MANVL
    FROM PHIEUNHAPKHO_DT
    WHERE ID=@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
    --LẤY NOTE HẠ CẤP
    SELECT @NoteHaCap = TRIM(NOTEHACAP)
    FROM PHIEUNHAPKHO_DT
    WHERE ID=@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7

    IF @NoteHaCap ='0' OR @NoteHaCap = 'H'
				BEGIN
        --LẤY GIÁ MỚI NHẤT SO VỚI NGÀY NHẬP KHO
        SELECT TOP 1
            @DonGia = CONVERT(INT,COST)
        FROM BANGGIANVL
        WHERE MASP = @Code AND APPLY_DATE<=@NgayApdung AND APPLY_DATE IS NOT NULL 
        ORDER BY APPLY_DATE DESC
        --UPDATE 2019-11-07
        --TRỪ 50K/M3 ĐỐI VỚI NHỮNG MÃ NHẬP NGOÀI ĐƠN HÀNG
        --KIỂM TRA TÌNH TRẠNG NHẬP, TRONG HAY NGOÀI ĐƠN HÀNG
        SELECT @isOver = OVER_PLAN, @khacKho = khackho
        FROM PHIEUNHAPKHO_DT
        WHERE ID=@LoopCounter



        IF @isOver=1
						SELECT @DonGia =@DonGia-300000

        IF @khacKho=1 and @tlkhackho <= 0.2
						SELECT @DonGia =@DonGia-50000
        IF @khacKho=1 and @tlkhackho > 0.2
						SELECT @DonGia =@DonGia-100000






        -- Nếu nhà cung cấp có COC thì sẽ không bị trừ 70k
        -- Và nhập kho bình thường

        --IF TRIM(@coc) ='N'
        --	SELECT @DonGia =@DonGia-70000

        -- NẾU TỶ LỆ CHÍNH PHẨM > TỶ LỆ MỐC TRÊN 
        -- THỲ ĐƯỢC CỘNG VÀO ĐƠN GIÁ CÔNG TY VÀ ĐƠN GIÁ LOẠI THEO HỆ SỐ 
        IF @rate >=@rateUp
						SELECT @DonGia =@DonGia+@hesoTruTheoTyLeTren
        -- Nếu tỷ lệ chính phẩm < tỷ lệ mốc dưới
        -- bị trừ vào đơn giá loại và đơn giá cty theo hệ số
        IF @rate <@rateDown
						BEGIN
            PRINT(CONVERT(varchar(30),@rate))
            DECLARE @NumPercenDiff as int,@SOTIENTRU AS INT
            SELECT @NumPercenDiff = CONVERT(INT,SUBSTRING(CONVERT(VARCHAR(30),@rate*100),0,3)) - ROUND(@rateDown*100,0)
            SELECT @SOTIENTRU = @NumPercenDiff*@hesoTruTheoTyLeDuoi
            SELECT @DonGia = @DonGia + @SOTIENTRU
        END
    END
			ELSE 
				BEGIN
        SELECT @DonGia = CONVERT(INT,COST)
        FROM CF_GIA_LOAI
        WHERE TRIM(CODE)=@NoteHaCap
    END
    -- CẬP NHẬT GIÁ
    UPDATE PHIEUNHAPKHO_DT SET DONGIA_CTY=@DonGia ,DONGIA_LOAI=@DonGia WHERE ID=@LoopCounter AND SOPHIEUNHAP=@SOPHIEU
    IF EXISTS(SELECT *
    FROM PHIEUNHAPKHO_DT
    WHERE SOPHIEUNHAP=@SOPHIEU AND ID=@LoopCounter AND DEL_FLAG='N' AND DELAI='N')
				BEGIN
        --- CHUẨN BỊ VÒNG LẶP HẠ CẤP
        DECLARE @LoopHCCouter INT, @MaxIDHC INT ,@MaNVLHC VARCHAR(30),@DonGiaLoai as int,@IDDT AS INT
        SELECT @LoopHCCouter =MIN(ID), @MaxIDHC =MAX(ID)
        FROM HACAP
        WHERE ID_DT=@LoopCounter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
        WHILE (@LoopHCCouter IS NOT NULL AND @LoopHCCouter <= @MaxIDHC)
					BEGIN
            SELECT @MaNVLHC = MANVL, @IDDT = ID_DT
            FROM HACAP
            WHERE ID=@LoopHCCouter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
            --KIỂM TRA TÌNH TRẠNG NHẬP, TRONG HAY NGOÀI ĐƠN HÀNG
            SELECT @isOver = OVER_PLAN
            FROM PHIEUNHAPKHO_DT
            WHERE ID=@LoopCounter
            --KIỂM TRA LOẠI HẠ CẤP
            SELECT @loaiHaCap = [TYPE]
            FROM HACAP
            WHERE ID=@LoopHCCouter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
            IF @loaiHaCap > 6  -- HÀNG LOẠI B,C, CỦI
							BEGIN
                SELECT @DonGiaHC = CONVERT(INT,COST)
                FROM CF_GIA_LOAI
                WHERE [TYPE]=@loaiHaCap

            END
						ELSE 
							BEGIN
                SELECT TOP 1
                    @DonGiaHC = CONVERT(INT,COST)
                FROM BANGGIANVL
                WHERE MASP = @MaNVLHC AND APPLY_DATE IS NOT NULL AND APPLY_DATE<=@NgayApdung
                ORDER BY APPLY_DATE DESC

            END

            IF @loaiHaCap <=6
							BEGIN

                -- NẾU TỶ LỆ CHÍNH PHẨM > TỶ LỆ MỐC TRÊN 
                -- THỲ ĐƯỢC CỘNG VÀO ĐƠN GIÁ CÔNG TY VÀ ĐƠN GIÁ LOẠI THEO HỆ SỐ 
                IF @rate >=@rateUp
									BEGIN
                    SELECT @DonGiaHC =@DonGiaHC+@hesoTruTheoTyLeTren
                -- Nếu tỷ lệ chính phẩm < tỷ lệ mốc dưới
                -- bị trừ vào đơn giá loại và đơn giá cty theo hệ số
                END
                IF @rate <@rateDown
									BEGIN
                    PRINT('DOWN')
                    SELECT @SOTIENTRU = @NumPercenDiff*@hesoTruTheoTyLeDuoi
                    SELECT @DonGiaHC = @DonGiaHC + @SOTIENTRU
                END
                --UPDATE 2019-11-07


                --TRỪ 50K/M3 ĐỐI VỚI NHỮNG MÃ NHẬP NGOÀI ĐƠN HÀNG
                IF @isOver=1 
									SELECT @DonGiaHC =@DonGiaHC-300000
            

            IF @khacKho=1 and @tlkhackho <= 0.2
									SELECT @DonGiaHC =@DonGiaHC-50000
			IF @khacKho=1 and @tlkhackho > 0.2
						SELECT @DonGiaHC =@DonGiaHC-100000





                --NẾU HẠ CẤP VỀ HẠ CẤP (KHÔNG TÍNH CÁC MÃ HẠ CẤP VỀ HÀNG LOẠI)
                -- TRỪ 70K NẾU KHÔNG PHẢI NHÀ CUNG CẤP COC
                --IF TRIM(@coc)='N' SELECT @DonGiaHC = @DonGiaHC-70000
                -- NEEU LA HANG HA CAP VE CHINH PHAM B THY KHO BI TRU 70K
                IF @loaiHaCap=1  SELECT @DonGiaLoai= @DonGiaHC
								ELSE SELECT @DonGiaLoai = @DonGiaHC-70000
            END
						ELSE 
							BEGIN
                --NẾU HẠ CẤP VỀ HÀNG LOẠI VÀ LOẠI B, C THỲ GIỮ GIÁ  THEOO GIÁ CỐ ĐỊNH
                SELECT @DonGiaLoai = @DonGiaHC
            END
            --CẬP NHẬT GIÁ CHO HẠ CẤP
            UPDATE HACAP SET DONGIA_CTY=@DonGiaHC,DONGIA_LOAI=@DonGiaLoai WHERE ID=@LoopHCCouter
            --
            SELECT @LoopHCCouter = MIN(ID)
            FROM HACAP
            WHERE ID>@LoopHCCouter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7 AND ID_DT=@LoopCounter
        END
    END
    --TĂNG GIÁ TRỊ CỦA BIẾN ĐẾM
    SELECT @LoopCounter = MIN(ID)
    FROM PHIEUNHAPKHO_DT
    WHERE ID>@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7 AND SOPHIEUNHAP=@SOPHIEU
    SET @value = 1
END

SELECT @value AS 'RESULT', @rate as 'TYLECP', @sum_kl_qc as [TONG_KL_QC], @sum_kl AS [TONG_KL_NHAN], @NumPercenDiff as [NUMDIFF]
GO
/****** Object:  StoredProcedure [nlg].[proc_Reset_Gia_theo_So_phieu_V3_EDIT]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     PROC [nlg].[proc_Reset_Gia_theo_So_phieu_V3_EDIT] @SOPHIEU AS VARCHAR(30),@value bit output
AS
DECLARE @LoopCounter INT,@MaxID INT, @Code as VARCHAR(30),@DonGia INT,@MaSP varchar(30),@Vung varchar(30),
		@NgayApdung date,@NoteHaCap nchar(10),@loaiHaCap as int,@DonGiaHC INT,@isOver as bit,@coc as nchar(10)
		,@rate as float,@rateUp as float,@rateDown as float,@hesoTruTheoTyLeDuoi as int,@hesoTruTheoTyLeTren as int,
		@sum_kl as float,@sum_kl_qc as float,@qcHeight int,@QCWIDTH INT
		 --SELECT @NgayApdung = CONVERT(DATE,GETDATE())   -- LAAYS NHAM NGAY
		  SELECT @NgayApdung = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@SOPHIEU 
		 --LẤY THÔNG TIN VÙNG CỦA BIÊN BẢN
		 SELECT @Vung = VUNG,@coc= COC  FROM PROVIDERS WHERE CODE = (SELECT MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@SOPHIEU AND DEL_FLAG='N' )
		 --LẤY THÔNG TIN LOOPID CHO BẢNG CHI TIẾT PHIẾU NHẬP KHO
		 SELECT @LoopCounter = min(ID),@MaxID = max(ID) FROM PHIEUNHAPKHO_DT WHERE SOPHIEUNHAP=@SOPHIEU AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
		 -- LẤY THÔNG TIN TỶ LỆ CHÍNH PHẨM CỦA BIÊN BẢN
		 

		SELECT @sum_kl = ROUND(SUM(i.KL_KHO),4) ,@sum_kl_qc = ROUND(SUM(i.KL_QC),4)
		FROM
			(SELECT ROUND((PT.SOTHANH_BO * PT.SAMPLEQTY - (
			SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID AND DEL_FLAG='N' GROUP BY ID_DT
			)) /(PT.SAMPLEQTY*PT.SOTHANH_BO) ,4 ) AS 'TYLE',
			ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO),4) AS 'KL_KHO',
			(PT.SOTHANH_BO * PT.SAMPLEQTY - (
			SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID  AND DEL_FLAG='N' GROUP BY ID_DT
			)) /(PT.SAMPLEQTY*PT.SOTHANH_BO) *
			(PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO) AS 'KL_QC'
			FROM PHIEUNHAPKHO_DT AS PT
			INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
			INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
			WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND PT.SOPHIEUNHAP IN (
			SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE   ALLOWMODIFY='N')
			AND PT.NOTEHACAP ='0' AND SOPHIEUNHAP=TRIM(@SOPHIEU)) AS i

		SELECT @rate = ROUND(@sum_kl_qc/@sum_kl,4)
		PRINT(CONVERT(varchar(30),@rate))
		---- LẤY TỶ LỆ MỐC TRÊN VÀ TỶ LỆ MỐC DƯỚI
		SELECT TOP 1 @rateDown = TYLE,@hesoTruTheoTyLeDuoi=HESO FROM CONFIG_TYLE WHERE TRIM([TYPE])='DOWN'
		SELECT TOP 1 @rateUp = TYLE,@hesoTruTheoTyLeTren=HESO FROM CONFIG_TYLE WHERE TRIM([TYPE])='UP'
		--kiểm tra điều kiện
		

 WHILE(@LoopCounter IS NOT NULL AND @LoopCounter <= @MaxID)

 BEGIN 
 -- LẤY MÃ SP NẾU CÓ
			SELECT @Code = MANVL FROM PHIEUNHAPKHO_DT WHERE ID=@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
			--LẤY NOTE HẠ CẤP
			SELECT @NoteHaCap = TRIM(NOTEHACAP) FROM PHIEUNHAPKHO_DT WHERE ID=@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
			
			IF @NoteHaCap ='0' OR @NoteHaCap = 'H'
				BEGIN
					--LẤY GIÁ MỚI NHẤT SO VỚI NGÀY NHẬP KHO
					SELECT TOP 1 @DonGia = CONVERT(INT,COST) FROM BANGGIANVL WHERE MASP = @Code  AND APPLY_DATE<=@NgayApdung AND APPLY_DATE IS NOT NULL  ORDER BY APPLY_DATE DESC
					--UPDATE 2019-11-07
					--TRỪ 50K/M3 ĐỐI VỚI NHỮNG MÃ NHẬP NGOÀI ĐƠN HÀNG
					--KIỂM TRA TÌNH TRẠNG NHẬP, TRONG HAY NGOÀI ĐƠN HÀNG
					SELECT @isOver = OVER_PLAN,@qcHeight = DAY,@QCWIDTH= RONG FROM PHIEUNHAPKHO_DT WHERE ID=@LoopCounter



					
						
					--- 2019-01-21\
					--NẾU CHIỀU DẦY QUI CÁCH LỚN HƠN HOẶC BẰNG 24 THỲ  ĐƯỢC TÍNH ĐƠN GIÁ VÁN GHÉP THANH
					IF @qcHeight >= 24 
						BEGIN
							-- NẾU BẢN RỘNG = 50 THỲ GIÁ LÀ 3700000
							-- CÒN LẠI LÀ 4 CỦ
							IF @QCWIDTH = 50
								SELECT @DonGia = 3700000
							ELSE 
								SELECT @DonGia = 4000000
						END
					ELSE 
						SELECT @DonGia = @DonGia -1000000
						
					-- Nếu nhà cung cấp có COC thì sẽ không bị trừ 70k
					-- Và nhập kho bình thường
					IF TRIM(@coc) ='N' AND TRIM(@NoteHaCap) ='0'
						SELECT @DonGia =@DonGia-70000

					-- NẾU TỶ LỆ CHÍNH PHẨM > TỶ LỆ MỐC TRÊN 
					-- THỲ ĐƯỢC CỘNG VÀO ĐƠN GIÁ CÔNG TY VÀ ĐƠN GIÁ LOẠI THEO HỆ SỐ 
					IF @rate >=@rateUp
						SELECT @DonGia =@DonGia+@hesoTruTheoTyLeTren
					-- Nếu tỷ lệ chính phẩm < tỷ lệ mốc dưới
					-- bị trừ vào đơn giá loại và đơn giá cty theo hệ số
					IF @rate <@rateDown
						BEGIN
							PRINT(CONVERT(varchar(30),@rate))
							DECLARE @NumPercenDiff as int,@SOTIENTRU AS INT
							SELECT @NumPercenDiff = CONVERT(INT,SUBSTRING(CONVERT(VARCHAR(30),@rate*100),0,3)) - ROUND(@rateDown*100,0)
							SELECT @SOTIENTRU = @NumPercenDiff*@hesoTruTheoTyLeDuoi
							SELECT @DonGia = @DonGia + @SOTIENTRU
						END
				END
			ELSE 
				BEGIN
					SELECT  @DonGia = CONVERT(INT,COST)  FROM CF_GIA_LOAI WHERE TRIM(CODE)=@NoteHaCap
				END
			-- CẬP NHẬT GIÁ
			UPDATE PHIEUNHAPKHO_DT SET DONGIA_CTY=@DonGia ,DONGIA_LOAI=@DonGia WHERE ID=@LoopCounter AND SOPHIEUNHAP=@SOPHIEU
				
			IF EXISTS(SELECT * FROM PHIEUNHAPKHO_DT WHERE SOPHIEUNHAP=@SOPHIEU AND ID=@LoopCounter AND DEL_FLAG='N' AND DELAI='N')
				BEGIN
					--- CHUẨN BỊ VÒNG LẶP HẠ CẤP
					DECLARE @LoopHCCouter INT, @MaxIDHC INT ,@MaNVLHC VARCHAR(30),@DonGiaLoai as int,@IDDT AS INT
					SELECT @LoopHCCouter =MIN(ID),@MaxIDHC =MAX(ID) FROM HACAP WHERE ID_DT=@LoopCounter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
					WHILE (@LoopHCCouter IS NOT NULL AND @LoopHCCouter <= @MaxIDHC)
					BEGIN
						SELECT @MaNVLHC = MANVL,@IDDT = ID_DT,@qcHeight = DAY,@QCWIDTH=RONG FROM HACAP WHERE ID=@LoopHCCouter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
						--KIỂM TRA TÌNH TRẠNG NHẬP, TRONG HAY NGOÀI ĐƠN HÀNG
						SELECT @isOver = OVER_PLAN FROM PHIEUNHAPKHO_DT WHERE ID=@LoopCounter
						--KIỂM TRA LOẠI HẠ CẤP
						SELECT @loaiHaCap = [TYPE] FROM HACAP WHERE ID=@LoopHCCouter AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7
						IF @loaiHaCap > 6  -- HÀNG LOẠI B,C, CỦI
							BEGIN
								SELECT @DonGiaHC = CONVERT(INT,COST)  FROM CF_GIA_LOAI WHERE [TYPE]=@loaiHaCap
						
							END
						ELSE 
							BEGIN
								SELECT TOP 1 @DonGiaHC = CONVERT(INT,COST) FROM BANGGIANVL WHERE MASP = @MaNVLHC AND APPLY_DATE IS NOT NULL  AND APPLY_DATE<=@NgayApdung  ORDER BY APPLY_DATE DESC
						
							END
				
						IF @loaiHaCap <=6

							BEGIN
								
								--*****************************************
								--- 2019-01-21\
								--NẾU CHIỀU DẦY QUI CÁCH LỚN HƠN HOẶC BẰNG 24 THỲ  ĐƯỢC TÍNH ĐƠN GIÁ VÁN GHÉP THANH
								IF @qcHeight >= 24 
									BEGIN
										-- NẾU BẢN RỘNG = 50 THỲ GIÁ LÀ 3700000
										-- CÒN LẠI LÀ 4 CỦ
										IF @QCWIDTH > 50
											SELECT @DonGiaHC = 4000000
										ELSE 
											SELECT @DonGiaHC = 3700000
									END
								ELSE 
								SELECT @DonGiaHC = @DonGiaHC-1000000
								---*****************************************************


								-- NẾU TỶ LỆ CHÍNH PHẨM > TỶ LỆ MỐC TRÊN 
								-- THỲ ĐƯỢC CỘNG VÀO ĐƠN GIÁ CÔNG TY VÀ ĐƠN GIÁ LOẠI THEO HỆ SỐ 
								IF @rate >=@rateUp
									BEGIN
										SELECT @DonGiaHC =@DonGiaHC+@hesoTruTheoTyLeTren
										-- Nếu tỷ lệ chính phẩm < tỷ lệ mốc dưới
										-- bị trừ vào đơn giá loại và đơn giá cty theo hệ số
									END
								IF @rate <@rateDown
									BEGIN
									PRINT('DOWN')
										SELECT @SOTIENTRU = @NumPercenDiff*@hesoTruTheoTyLeDuoi
										SELECT @DonGiaHC = @DonGiaHC + @SOTIENTRU
									END
								--UPDATE 2019-11-07
								--TRỪ 50K/M3 ĐỐI VỚI NHỮNG MÃ NHẬP NGOÀI ĐƠN HÀNG

								--IF @isOver=1 
								--BEGIN
								--	IF @NgayApdung>='2019-11-26'
								--		SELECT @DonGiaHC =@DonGiaHC-200000
								--	ELSE
								--		SELECT @DonGiaHC =@DonGiaHC-50000
								--END









								--NẾU HẠ CẤP VỀ HẠ CẤP (KHÔNG TÍNH CÁC MÃ HẠ CẤP VỀ HÀNG LOẠI)
								-- TRỪ 70K NẾU KHÔNG PHẢI NHÀ CUNG CẤP COC
								IF TRIM(@coc)='N' SELECT @DonGiaHC = @DonGiaHC-70000
								-- NEEU LA HANG HA CAP VE CHINH PHAM B THY KHO BI TRU 70K
								IF @loaiHaCap=1  SELECT @DonGiaLoai= @DonGiaHC
								ELSE SELECT @DonGiaLoai = @DonGiaHC-70000
							END
						ELSE 
							BEGIN
								--NẾU HẠ CẤP VỀ HÀNG LOẠI VÀ LOẠI B, C THỲ GIỮ GIÁ  THEOO GIÁ CỐ ĐỊNH
								SELECT @DonGiaLoai = @DonGiaHC
							END
						--CẬP NHẬT GIÁ CHO HẠ CẤP
						UPDATE HACAP SET DONGIA_CTY=@DonGiaHC,DONGIA_LOAI=@DonGiaLoai WHERE ID=@LoopHCCouter
						--
						SELECT @LoopHCCouter = MIN(ID) FROM HACAP
						WHERE ID>@LoopHCCouter  AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7 AND ID_DT=@LoopCounter
					END
				END
			--TĂNG GIÁ TRỊ CỦA BIẾN ĐẾM
			SELECT @LoopCounter = MIN(ID) FROM PHIEUNHAPKHO_DT
			WHERE ID>@LoopCounter AND DELAI='N' AND DEL_FLAG='N' AND LEN(TRIM(MANVL))>=7 AND SOPHIEUNHAP=@SOPHIEU
			SET @value = 1	
END

SELECT @value AS 'RESULT',@rate as 'TYLECP',@sum_kl_qc as [TONG_KL_QC],@sum_kl AS [TONG_KL_NHAN],@NumPercenDiff as [NUMDIFF]

GO
/****** Object:  StoredProcedure [nlg].[proc_update_Group_Code]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [nlg].[proc_update_Group_Code] @code as varchar(40),@groupId as int
as
BEGIN
	BEGIN TRANSACTION
	DECLARE @RESULT AS BIT
		BEGIN TRY
			UPDATE BOM SET NHOM =@groupId WHERE CODE=@code
			UPDATE PHIEUNHAPKHO_DT SET CODENHOM =@groupId WHERE CODE =@code
			UPDATE PLAN_nlg SET GROUP_CODE =@groupId WHERE CODE=@code
			SELECT @RESULT = 1
			COMMIT
		END TRY
		BEGIN CATCH
			SELECT @RESULT = 0
			ROLLBACK
		END CATCH
	SELECT @RESULT AS [RESULT]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_update_ha_cap]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [nlg].[proc_update_ha_cap] @ID AS INT,
	@CODE AS VARCHAR(50),
	@SOTHANH AS INT,
	@TYPEID AS INT,
	@NOTE AS NVARCHAR(200),
	@GAPDOI AS NCHAR(10)
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE @TONGHACAP AS INT,@IDDT AS INT,@SOTHANHLAYMAU AS INT,@RESULT AS BIT,@MESSAGE AS NVARCHAR(100)
	UPDATE HACAP SET CODE=@CODE,SOTHANH = @SOTHANH,[TYPE] =@TYPEID,NOTE =@NOTE,GAPDOI=@GAPDOI WHERE ID=@ID
	--CAP NHẠT LẠI SỐ LƯỢNG CHÍNH PHẨM
	
	SELECT @IDDT = ID_DT FROM HACAP WHERE ID=@ID
	SELECT @SOTHANHLAYMAU = SAMPLEQTY*SOTHANH_BO  FROM PHIEUNHAPKHO_DT WHERE ID=@IDDT
	SELECT @TONGHACAP = SUM(SOTHANH) FROM HACAP WHERE ID_DT=@IDDT AND DEL_FLAG='N'

	IF @SOTHANHLAYMAU-@TONGHACAP>0 
		BEGIN
			UPDATE PHIEUNHAPKHO_DT SET QTY = @SOTHANHLAYMAU-@TONGHACAP WHERE ID=@IDDT
			SELECT @RESULT =1,@MESSAGE=N'THÀNH CÔNG !'
			COMMIT
		END
	ELSE
		BEGIN
			SELECT @RESULT=0,@MESSAGE=N'Số lượng nhập vào vượt quá số lượng lấy mẫu'
			ROLLBACK
		END
	
	SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [nlg].[proc_Update_SO_THANH_BO_NHAP_KHO]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     proc [nlg].[proc_Update_SO_THANH_BO_NHAP_KHO] @iddt as int,@SOTHANHBO AS INT,@RESULT AS BIT OUTPUT
AS
BEGIN
	BEGIN TRANSACTION
	UPDATE PHIEUNHAPKHO_DT SET SOTHANH_BO =@SOTHANHBO WHERE ID=@iddt
		DECLARE @sobo AS INT,-- số bó
		 @remainM3 as float,-- số lượng còn lại (m3)
		 @remainThanh as int,-- số lượng còn lại (Thanh)
		 @klQuiCach as float,--khối lượng của qui cách / 1 thanh
		 @CODENHOM as varchar(40),--- NHÓM mã nguyên vật liệu
		 @sothanh as int,-- tổng số thanh, bằng số bó * số thanh.bó
		 @sophieu as varchar(30), -- số phiếu 
		 @qty as int, --tổng số thanh đạt yêu cầu, phải cập nhật lại
		 @tongHaCap as int, -- tổng số thanh đã hạ cấp,
		 @soBoLayMau as int -- Số bó lấy mẫu

		--khai báo biến hk,th,mã nhà cung cấp, ngày nhập kho
		DECLARE @KH AS FLOAT,@TH AS FLOAT,@MANCC AS NCHAR(10),@ngaynhapkho as datetime,@MESSAGE AS NVARCHAR(100),
				@VUOT_KH AS BIT,@KH_TONG AS FLOAT,@TH_TONG AS FLOAT

		
		SELECT @CODENHOM = CODENHOM,@sobo=SOBO,@sophieu=SOPHIEUNHAP,@soBoLayMau=SAMPLEQTY,@VUOT_KH=OVER_PLAN FROM PHIEUNHAPKHO_DT WHERE ID=@iddt
		SELECT @sothanh = @sobo*@SOTHANHBO 

		--tính lại tổng số thanh đã hạ cấp
		SELECT @tongHaCap= sum(SOTHANH) from HACAP where ID_DT=@iddt group by ID_DT
		-- tính lại số lượng đạt chính phẩm
		SELECT @qty = @soBoLayMau*@SOTHANHBO - @tongHaCap
		print(N'Số thanh đạt chính phẩm:'+convert(varchar(30),@qty))
		-- cập nhật luôn số thanh đạt chính phẩm
		UPDATE PHIEUNHAPKHO_DT SET QTY = @qty WHERE ID=@iddt
		SELECT @ngaynhapkho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
		SELECT @MANCC = MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU=@sophieu
		-- TÍNH KẾ HOẠCH TỔNG CHO NHÓM QUI CÁCH (KẾ HOẠCH TỔNG)
		SELECT @KH_TONG  = SUM(PL.PLANQTY)
			FROM PLAN_nlg  AS PL
			INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
			WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho) AND 
			DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho) AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODENHOM
			GROUP BY PL.GROUP_CODE
		--TÍNH KẾ HOẠCH NHẬP CỦA NHÀ CUNG CẤP NÀY
		SELECT @KH = SUM(PL.PLANQTY)
			FROM PLAN_nlg  AS PL
			INNER JOIN PROVIDERS AS PR ON PR.CODE =PL.MANCC
			WHERE PL.DEL_FLAG='N' AND DATEPART(MONTH,PL.CREATED_AT) = DATEPART(MONTH,@ngaynhapkho)
			AND DATEPART(YEAR,PL.CREATED_AT) = DATEPART(YEAR,@ngaynhapkho)
			AND PL.MANCC=@MANCC AND PL.GROUP_CODE=@CODENHOM
			GROUP BY PL.GROUP_CODE
		-- TÍNH THỰC HIỆN TỔNG CHO QUI CÁCH NÀY
		SELECT @TH_TONG = SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)))
		FROM PHIEUNHAPKHO_DT AS PT
		INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.DEL_FLAG='N'
		INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
		AND PT.DEL_FLAG='N' AND DELAI='N' AND PT.CODENHOM=@CODENHOM AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
		AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho)
		GROUP BY PT.CODENHOM
		
		--KIỂM TRA MÃ NHẬP KHO ĐANG CẬP NHẬT NÀY LÀ MÃ NHẬP VƯỢT KẾ HOẠCH HAY KHÔNG
		-- NẾU LÀ VƯỢT KẾ HOẠCH THỲ KIỂM TRA KẾ HOẠCH TỔNG
		-- CÒN NẾU CẬP NHẬT CHO MÃ TRONG KẾ HOẠC THỲ KIỂM TRA THỰC HIỆN VÀ KẾ HOẠCH CHO NHÀ CUNG CẤP
		IF @VUOT_KH =1
			BEGIN
				--TÍNH THỰC HIỆN THEO NHÀ CUNG CẤP
				SELECT @TH = SUM(CAST((POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) as decimal(16,4)))
				FROM PHIEUNHAPKHO_DT AS PT
				INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP AND PN.MANCC=@MANCC AND PN.DEL_FLAG='N'
				INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
				AND PT.DEL_FLAG='N'  AND DELAI='N' AND PT.CODENHOM=@CODENHOM AND DATEPART(MONTH,PN.CREATED_AT)=DATEPART(MONTH,@ngaynhapkho)
				AND DATEPART(YEAR,PN.CREATED_AT)=DATEPART(YEAR,@ngaynhapkho)
				GROUP BY PT.CODENHOM

				SELECT @klQuiCach = (POWER(Cast(10 as float),CAST(-9 as float)) * SOBO*SOTHANH_BO*DAY*RONG*CAO) FROM PHIEUNHAPKHO_DT WHERE ID=@iddt
		
				SELECT @remainM3 = Round(@KH-@TH,2)
				print('So luong con lai m3 :'+convert(varchar(400),@remainM3))
				--SELECT @remainThanh =ROUND(@remainM3/ROUND(@klQuiCach,4),0)
				--print(convert(varchar(400),@sothanh))
				--print('So luong con lai :'+convert(varchar(400),@remainThanh))
				IF @remainM3>0
					BEGIN
						COMMIT
						SELECT @RESULT =1
					END
				ELSE
					BEGIN
						PRINT('ROLLBACK');
						ROLLBACK;
						SELECT @RESULT =0
					END
			END
		ELSE
			BEGIN
				--NẾU THỰC HIỆN TỔNG > KẾ HOẠCH TỔNG 
				-- ROLLBACK 
				-- BÁO FAIL SỐ LƯỢNG
				IF @TH_TONG>@KH_TONG
					BEGIN
						SELECT @RESULT=0,@MESSAGE=N'SỐ LƯỢNG VƯỢT QUÁ KẾ HOẠCH TỔNG THỂ '+CONVERT(VARCHAR(40),ROUND(@KH_TONG,4))
						ROLLBACK
					END
				ELSE
				-- NGƯỢC LẠI , NẾU THỰC HIỆN TỔNG <= KẾ HOẠCH TỔNG
				-- THỲ CHO PHÉP CẬP NHẬT 
				 BEGIN
					SELECT @RESULT=1, @MESSAGE = N'NHẬP NGOÀI KẾ HOẠCH : -> THÀNH CÔNG !'
					COMMIT
				 END
			END
		SELECT @RESULT AS 'RESULT',@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [nlg].[procGetTyLeKL]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [nlg].[procGetTyLeKL] 
as

SELECT PT.ID,PT.SOPHIEUNHAP,PT.CODE,CAST((PT.SOTHANH_BO * PT.SAMPLEQTY - (
SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID GROUP BY ID_DT
))*100 /(PT.SAMPLEQTY*PT.SOTHANH_BO) AS decimal(16,2) ) AS 'TYLE',
pn.MANCC,PR.NAME,ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO),4) AS 'KL_KHO',
ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO) * cast((SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID GROUP BY ID_DT)/(PT.SAMPLEQTY*PT.SOTHANH_BO) as decimal(8,2)) ,4) AS 'KL_QC',
PN.MAKHO

FROM PHIEUNHAPKHO_DT AS PT
INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND PT.SOPHIEUNHAP IN (
SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE   ALLOWMODIFY='N')
AND PT.NOTEHACAP ='0'
GO
/****** Object:  StoredProcedure [nlg].[procGetTyLeTheoNgay]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [nlg].[procGetTyLeTheoNgay] @fromDate as DateTime,@toDate as DateTime
as

SELECT PT.ID,PT.SOPHIEUNHAP,PT.CODE,CAST((PT.SOTHANH_BO * PT.SAMPLEQTY - (
SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID AND DEL_FLAG='N' GROUP BY ID_DT
))*100 /(PT.SAMPLEQTY*PT.SOTHANH_BO) AS decimal(16,2) ) AS 'TYLE',
pn.MANCC,PR.NAME,ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO),4) AS 'KL_KHO',
ROUND((PT.SOTHANH_BO*POWER(Cast(10 as float),CAST(-9 as float))*PT.DAY*PT.RONG*PT.CAO*PT.SOBO) * cast((SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID AND DEL_FLAG='N' GROUP BY ID_DT)/(PT.SAMPLEQTY*PT.SOTHANH_BO) as decimal(8,2)) ,4) AS 'KL_QC',
PN.MAKHO

FROM PHIEUNHAPKHO_DT AS PT
INNER JOIN PHIEUNHAPKHO AS PN ON PN.SOPHIEU = PT.SOPHIEUNHAP
INNER JOIN PROVIDERS AS PR ON PR.CODE = PN.MANCC
WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND PT.SOPHIEUNHAP IN (
SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE   ALLOWMODIFY='N' AND CREATED_AT BETWEEN @fromDate AND @toDate)
AND PT.NOTEHACAP ='0'
GO
/****** Object:  StoredProcedure [nlg].[procGetTyLeTheoQuiCach]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 create proc [nlg].[procGetTyLeTheoQuiCach] @fromDate as DateTime,@toDate as DateTime
as
SELECT PT.ID,PT.SOPHIEUNHAP,PT.CODE,CAST((PT.SOTHANH_BO * PT.SAMPLEQTY - (
SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID GROUP BY ID_DT
))*100 /(PT.SAMPLEQTY*PT.SOTHANH_BO) AS decimal(16,2) ) AS 'TYLE',(PT.SAMPLEQTY*PT.SOTHANH_BO) AS 'SOTHANHMAU' ,
(SELECT SUM(SOTHANH) FROM HACAP WHERE ID_DT=PT.ID GROUP BY ID_DT) AS 'SLHC',
cast(100*(SELECT SUM(CAST(SOTHANH AS float)) FROM HACAP WHERE ID_DT=PT.ID GROUP BY ID_DT)/(PT.SAMPLEQTY*PT.SOTHANH_BO) as decimal(8,2)) as 'tyleHC'
FROM PHIEUNHAPKHO_DT AS PT
WHERE PT.DEL_FLAG='N' AND PT.DELAI='N' AND PT.SOPHIEUNHAP IN (
SELECT SOPHIEU FROM PHIEUNHAPKHO WHERE   ALLOWMODIFY='N' AND CREATED_AT BETWEEN @fromDate AND @toDate)
AND PT.NOTEHACAP ='0'
GO
/****** Object:  StoredProcedure [nlg].[sp_chuyenNhapKhoVeHaCap]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [nlg].[sp_chuyenNhapKhoVeHaCap] @id int,@codeChange varchar(30),@day int,@rong int ,@dai int,@fromCode varchar(30),@username varchar(30),@sophieu varchar(30)
as
BEGIN
	SET XACT_ABORT ON

	BEGIN TRAN
		BEGIN TRY
			--lấy vùng của biên bản
			DECLARE @vung varchar(30)
			SELECT @vung = VUNG FROM PROVIDERS	WHERE CODE IN (SELECT MANCC FROM PHIEUNHAPKHO WHERE SOPHIEU =@sophieu)
			-- LẤY MÃ GIÁ CỦA SẢN PHẨM
			DECLARE @MASP varchar(50)
			exec sp_layMaGiaSanPham @codeChange,@vung,@maSanPham=@MASP OUTPUT
			-- LẤY NGÀY CỦA BIÊN BẢN(NGÀY NHẬP KHO)
			DECLARE @ngayNhapKho as Datetime
			SELECT @ngayNhapKho = CREATED_AT FROM PHIEUNHAPKHO WHERE SOPHIEU =@sophieu
			-- LẤY GIÁ HIỆN TẠI ĐANG ÁP DỤNG
			DECLARE @GIASP INT
			SELECT TOP 1  @GIASP = COST FROM BANGGIANVL WHERE MASP=@MASP AND APPLY_DATE IS NOT NULL AND VUNG=@vung AND APPLY_DATE  <=@ngayNhapKho ORDER BY APPLY_DATE DESC

			BEGIN TRAN
				BEGIN TRY
				   UPDATE PHIEUNHAPKHO_DT SET CODE = @codeChange,NOTEHACAP='H',DAY=@day,RONG =@rong,CAO=@dai,NOTE=N'HC Từ '+@fromCode,UPDATE_BY=@username,UPDATED_AT=GETDATE(),
					MANVL=@MASP,DONGIA_CTY=@GIASP,DONGIA_LOAI=@GIASP  
				   WHERE ID=@id
				   UPDATE HACAP SET DEL_FLAG='Y',NOTE=N'Chính phẩm => nhập hạ cấp' WHERE ID_DT=@id
					COMMIT
				END TRY
			BEGIN CATCH
			ROLLBACK
			   DECLARE @ErrorMessage VARCHAR(2000)
			   SELECT @ErrorMessage = 'Lỗi: ' + ERROR_MESSAGE()
			   RAISERROR(@ErrorMessage, 16, 1)
			END CATCH
			---COMMIT
			COMMIT
		END TRY
		BEGIN CATCH
			ROLLBACK
			DECLARE @errorMessgae nvarchar(1000)
			SELECT @errorMessgae =N'Lỗi '+ERROR_MESSAGE()
			RAISERROR(@errorMessage,16,1)
		END CATCH
END
GO
/****** Object:  StoredProcedure [nlg].[sp_layMaGiaSanPham]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [nlg].[sp_layMaGiaSanPham] @code varchar(30), @vung nchar(10),@maSanPham varchar(50) output
AS
	SET NOCOUNT ON;  
	SELECT  @maSanPham =  MASP FROM BANGGIANVL WHERE MASP LIKE '%'+@code+'%' AND VUNG=@vung ORDER BY APPLY_DATE DESC
	
RETURN
GO
/****** Object:  StoredProcedure [nlg].[testWeek]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [nlg].[testWeek] @year as int,@month as int
as
declare @week0 int
set @week0 = DATEPART(week,CAST(@year as nvarchar(20))+'-'+CAST(@month as nvarchar(20))+'-01')
select @week0
GO
/****** Object:  StoredProcedure [wood].[Proc_Approval_Price]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create       PROC [wood].[Proc_Approval_Price]
@REQ_ID INT,@UID INT,@STATUS INT,@APPROVAL_DATE VARCHAR(430),@APPROVAL_NOTE NVARCHAR(300)
AS
BEGIN
	DECLARE @RESULT AS BIT,@MESSAGE AS NVARCHAR(200)
	IF CONVERT(datetime,@APPROVAL_DATE) >= GETDATE()
	BEGIN
		BEGIN TRAN
		BEGIN TRY
			UPDATE wood.REQ_PRICE SET APPROVAL_AT=CONVERT(datetime,@APPROVAL_DATE),APPROVAL_BY=@UID,APPROVAL_STATUS=@STATUS,
			APPROVAL_NOTE=@APPROVAL_NOTE WHERE ID=@REQ_ID
			UPDATE wood.WOOD_PRICE_LIST SET ISNEW='N' 
			WHERE  ITEM_ID IN (SELECT ITEM_ID FROM wood.WOOD_PRICE_LIST WHERE REQ_ID=@REQ_ID) AND
			REGION_ID IN (SELECT REGION_ID FROM wood.WOOD_PRICE_LIST WHERE REQ_ID=@REQ_ID) AND
			[TYPE] IN (SELECT [TYPE] FROM wood.WOOD_PRICE_LIST WHERE REQ_ID=@REQ_ID) AND
			[WTYPE] IN (SELECT [WTYPE] FROM wood.WOOD_PRICE_LIST WHERE REQ_ID=@REQ_ID) AND
			[ITYPE] IN (SELECT [ITYPE] FROM wood.WOOD_PRICE_LIST WHERE REQ_ID=@REQ_ID) AND
			ISNEW = 'Y'

			UPDATE wood.WOOD_PRICE_LIST SET APPLY_STATUS=@STATUS,ISNEW='Y',APPLY_DATE=CONVERT(datetime,@APPROVAL_DATE),APPLY_BY=@UID WHERE REQ_ID=@REQ_ID
			SELECT @RESULT =1,@MESSAGE=N'Thành công !' 
			COMMIT
		END TRY
		BEGIN CATCH
			SELECT  @RESULT =0,@MESSAGE=ERROR_MESSAGE()
			ROLLBACK
		END CATCH
	END
	ELSE
		SELECT  @RESULT =0,@MESSAGE=N'NGÀY ÁP DỤNG KHÔNG CHÍNH XÁC !'
		SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Change_Map_Condition]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create     Proc [wood].[Proc_Change_Map_Condition](
	@REGION_ID INT,@CONDITION_ID INT, @MAP_ID INT
)
AS
BEGIN
	DECLARE @RESULT AS BIT, @MESSAGE AS NVARCHAR(200)
	IF EXISTS (SELECT * FROM wood.OPT_MAP_CONDITION WHERE REGION_ID=@REGION_ID AND COND_ID=@CONDITION_ID)
		BEGIN
		--UPDATE
			BEGIN TRY
				DELETE FROM wood.OPT_MAP_CONDITION WHERE ID = @MAP_ID
				SELECT @RESULT =1 ,@MESSAGE =  N'THÀNH CÔNG !'
			END TRY
			BEGIN CATCH
				SELECT @RESULT=0,@MESSAGE =ERROR_MESSAGE()
			END CATCH
		END
	ELSE
		BEGIN
		--INSERT
			BEGIN TRY
				INSERT INTO wood.OPT_MAP_CONDITION(REGION_ID,COND_ID) VALUES(@REGION_ID,@CONDITION_ID)
				SELECT @RESULT =1 ,@MESSAGE =  N'THÀNH CÔNG !'
			END TRY
			BEGIN CATCH
			SELECT @RESULT=0,@MESSAGE =ERROR_MESSAGE()
			END CATCH
		END
	SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Completed_Receipt]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create        PROC [wood].[Proc_Completed_Receipt]
@RECEIPT_ID  INT,@OTHER_SUPPORT_FEE INT,@TOTAL_PAY INT,@AVG_PRICE INT,@WH_VOLUMN FLOAT,
@QC_VOLUMN FLOAT,@INPUT_RATE FLOAT,@PAY_RATE FLOAT,@TOTAL_NOT_TAX INT,@APPROVAL_STATUS INT,@UID INT,@MANUAL INT
AS
BEGIN
		BEGIN TRAN
		BEGIN TRY
			INSERT INTO wood.WOOD_PAY_SAVE([RECEIPT_ID],[OTHER_SUPPORT_FEE],[TOTAL_PAY],[AVERAGE_PRICE],
			[WH_VOLUMN],[QC_VOLUMN],[INPUT_RATE],[PAY_RATE],[TOTAL_NOT_TAX],APPROVAL_STATUS,CREATE_AT,
			CREATE_BY,[MANUAL])
			VALUES(@RECEIPT_ID,@OTHER_SUPPORT_FEE,@TOTAL_PAY,@AVG_PRICE,@WH_VOLUMN,@QC_VOLUMN,@INPUT_RATE,@PAY_RATE,@TOTAL_NOT_TAX,@APPROVAL_STATUS,GETDATE(),@UID,@MANUAL)

			UPDATE wood.WH_RECEIPT set [LOCK]=1 WHERE ID=@RECEIPT_ID
			COMMIT
		END TRY
		BEGIN CATCH 
			ROLLBACK
		END CATCH
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Create_Detail_WH_Receipt]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create         PROC [wood].[Proc_Create_Detail_WH_Receipt]
	@RECEIPT_ID INT,@ITEM_ID INT,@PCS_PACKAGE INT,@PACKAGE_QUANTITY INT,
	@INPUT_TYPE_ID INT,@NOTE NVARCHAR(300),@LEAVE  BIT,@OVERPLAN BIT,@UID INT,@DTYPE AS NCHAR(10),@WTYPE AS INT
AS
BEGIN
	DECLARE @RESULT BIT 
	BEGIN TRY
		INSERT INTO wood.WH_RECEIPT_DTL([WH_RECEIPT_ID],[ITEM_ID],[PCS_PER_PACKAGE],[PACKAGE_QUANTITY],[INPUT_TYPE_ID],
		[NOTE],[LEAVE],[OVER_PLAN],[DEL_FLAG],CREATE_AT,CREATE_BY,DTYPE,WTYPE)
		VALUES(@RECEIPT_ID,@ITEM_ID,@PCS_PACKAGE,@PACKAGE_QUANTITY,@INPUT_TYPE_ID,@NOTE,@LEAVE,@OVERPLAN,'N',GETDATE(),@UID,@DTYPE,@WTYPE)
		SET @RESULT=1
		SELECT @RESULT AS [RESULT],N'Thành công !' AS [MESSAGE],@LEAVE AS LEAVE
	END TRY
	BEGIN CATCH
		SET @RESULT=0
		SELECT 0 AS [RESULT],ERROR_MESSAGE() AS [MESSAGE] 
	END CATCH
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Create_WareHouse_Receipt]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE         PROC [wood].[Proc_Create_WareHouse_Receipt]
	@WAREHOUSE_ID  INT, @RECEIPT_DATE DATETIME,@CAR_LICENSE_PLATE VARCHAR(50), @VENDOR_ID INT,
	@FORLIFT  BIT,@UID INT,@MODULECODE VARCHAR(300)
AS
BEGIN
	DECLARE @YEAR AS INT,@MONTH  AS INT,@MAX_NUMBER_OF_MONTH AS INT,@RESULT AS BIT,@MESSAGE AS NVARCHAR(300),@NEW_RECEIPT_ID AS INT,@NEW_ID AS UNIQUEIDENTIFIER
	SELECT @MONTH = DATEPART(MONTH,@RECEIPT_DATE),@YEAR = DATEPART(YEAR,@RECEIPT_DATE)
	SET @NEW_ID = NEWID()
	SELECT @MAX_NUMBER_OF_MONTH = MAX(NUMBER_OF_MONTH) FROM wood.WH_RECEIPT WHERE [WAREHOUSE_ID]=@WAREHOUSE_ID AND [MONTH] =@MONTH AND [YEAR] = @YEAR
	 AND DEL_FLAG='N' AND WAREHOUSE_ID = @WAREHOUSE_ID
	IF @MAX_NUMBER_OF_MONTH IS NULL
		SELECT @MAX_NUMBER_OF_MONTH = 0
	BEGIN TRY
		INSERT INTO wood.WH_RECEIPT([GUID],NUMBER_OF_MONTH,[MONTH],[YEAR],[WAREHOUSE_ID],[VENDOR_ID],[CAR_LICENSE_PLATE],[ALLOW_INSPECTION],
		[ALLOW_PAY],[FORKLIFT],[RECEIPT_DATE],[CREATE_AT],[CREATE_BY],[DEL_FLAG],[MODULE],[QC_STAFF],[LOCK])
		VALUES(@NEW_ID,@MAX_NUMBER_OF_MONTH+1,@MONTH,@YEAR,@WAREHOUSE_ID,@VENDOR_ID,@CAR_LICENSE_PLATE,1,0,@FORLIFT,@RECEIPT_DATE,GETDATE(),@UID,'N',@MODULECODE,@UID,0)
		SELECT @NEW_RECEIPT_ID = ID FROM wood.WH_RECEIPT WHERE [GUID]=@NEW_ID
		SELECT @RESULT =1, @MESSAGE=N' Thêm mới thành công !'
	END TRY
	BEGIN CATCH
		SELECT @RESULT=0,@MESSAGE =ERROR_MESSAGE()
	END CATCH

	SELECT @RESULT AS [RESULT],@MESSAGE AS  [MESSAGE],@NEW_RECEIPT_ID AS [NEW_RECEIPT_ID]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Create_Wood_Inspection]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create         PROC [wood].[Proc_Create_Wood_Inspection] @RECEIPT_ID INT,@ITEM_ID INT,@NOTE NVARCHAR(300),
	@SIZE_OUT_RATE FLOAT,@HUMIDITY FLOAT,@ISDOUBLE NCHAR(10),@INPUT_TYPE_ID INT,@UID INT,@SAMPLE_QUANTITY INT,@DEFECT_QTY INT,@DTYPE NCHAR(10),@RATE_NONLI AS FLOAT,
	@RATE_A1 FLOAT
AS
BEGIN
	DECLARE @RESULT AS BIT , @MESSAGE AS NVARCHAR(300),@WTYPE AS INT
	SELECT @WTYPE = WTYPE FROM wood.WH_RECEIPT_DTL WHERE ID = @RECEIPT_ID
	BEGIN TRY
		INSERT INTO wood.WOOD_INSPECTION([RECEIPT_ID],[INPUT_TYPE_ID],[ITEM_ID],[NOTE],[SIZE_OUT_RATE],[HUMIDITY],[IS_DOUBLE],[DEL_FLAG],[CREATE_AT],[CREATE_BY],[DEFECT_QTY],[WTYPE],[DTYPE],
		RATE_NONLI,RATE_A1)
		VALUES(@RECEIPT_ID,@INPUT_TYPE_ID,@ITEM_ID,@NOTE,@SIZE_OUT_RATE,@HUMIDITY,@ISDOUBLE,'N',GETDATE(),@UID,@DEFECT_QTY,@WTYPE,@DTYPE,@RATE_NONLI,@RATE_A1)
		UPDATE  wood.WH_RECEIPT_DTL SET SAMPLE_QUANTITY=@SAMPLE_QUANTITY WHERE ID = @RECEIPT_ID
		SELECT @RESULT=1,@MESSAGE=N'Thành công !'
	END TRY
	BEGIN CATCH
		SELECT @RESULT=0,@MESSAGE=ERROR_MESSAGE()
	END CATCH
	SELECT @RESULT AS [RESULT], @MESSAGE AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_get_Out_Price]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROC [wood].[Proc_get_Out_Price] 
(@REGION_ID INT,@PARAM_INPUT_TYPE INT,@RATE FLOAT,@ID_INSPECT INT , @RESULT AS INT OUTPUT)
AS
BEGIN
	DECLARE @LOOP_COUTER INT,@MAX_ID INT,@NUM_OUT INT = 0
	-- LẤY TẤT CẢ CÁC ĐIỀU KIỆN CỦA BẢNG GIÁ
	SELECT @LOOP_COUTER= MIN(ID),@MAX_ID =MAX(ID) FROM wood.OPT_MAP_CONDITION WHERE REGION_ID = @REGION_ID
	-- LOOP QUA CÁC BẢN GHI
	WHILE @LOOP_COUTER<= @MAX_ID
	BEGIN
		DECLARE @CODE VARCHAR(300),@HESO INT,@ID_CONDITION INT,@PAY_RATE FLOAT
		SELECT @ID_CONDITION=COND_ID FROM wood.OPT_MAP_CONDITION WHERE ID=@LOOP_COUTER
		SELECT @CODE = CODE, @HESO = HESO,@PAY_RATE = PAY_RATE FROM wood.OPT_CONDITIONS WHERE ID = @ID_CONDITION
		IF @CODE = 'DK1'
			BEGIN
				IF @PARAM_INPUT_TYPE =  100017 -- HÀNG NON LI TRỪ THEO SỐ PHẦN TRĂM LOẠI
					SELECT @NUM_OUT =@NUM_OUT-@NUM_OUT-@HESO -- TRỪ 100K
			END
		IF @CODE = 'DK2'
			BEGIN
				IF @PARAM_INPUT_TYPE =  100017  AND @RATE >0.25-- HÀNG NON LI TRỪ  100% LÔ HÀNG
					SELECT @NUM_OUT =@NUM_OUT-@NUM_OUT-@HESO --
					-- NÂNG TỶ LỆ THANH TOÁN LÊN SỐ % 
					UPDATE wood.WOOD_INSPECTION SET PAY_RATE = @PAY_RATE WHERE ID = @ID_INSPECT
			END
		IF @CODE = 'DK5'
			BEGIN
				IF @PARAM_INPUT_TYPE =  100018  AND @RATE >0.05 AND @RATE <=0.1-- HÀNG tươi TRỪ THEO SỐ PHẦN TRĂM LOẠI
					SELECT @NUM_OUT =@NUM_OUT-@NUM_OUT-@HESO 
			END
		IF @CODE = 'DK6'
			BEGIN
				IF @PARAM_INPUT_TYPE =  100018  AND @RATE >0.1 AND @RATE <=0.3-- HÀNG NON LI TRỪ  100% LÔ HÀNG
					SELECT @NUM_OUT =@NUM_OUT-@NUM_OUT-@HESO --
					-- NÂNG TỶ LỆ THANH TOÁN LÊN SỐ % 
					UPDATE wood.WOOD_INSPECTION SET PAY_RATE = @PAY_RATE WHERE ID = @ID_INSPECT
			END
		--IF @CODE = 'DK_NONLI'
		--	BEGIN
		--		IF @PARAM_INPUT_TYPE =  100018 -- HÀNG TƯƠI
		--			SELECT @NUM_OUT =@NUM_OUT-150000 -- TRỪ 100K
		--	END
		SELECT @LOOP_COUTER = MIN(ID) FROM wood.OPT_MAP_CONDITION WHERE REGION_ID = @REGION_ID AND  ID >@LOOP_COUTER
	END
	SELECT @NUM_OUT AS 'RESULT'
END
GO
/****** Object:  StoredProcedure [wood].[Proc_get_Pay_Cal_By_Receipt_id_Van]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE         PROC [wood].[Proc_get_Pay_Cal_By_Receipt_id_Van]
@RECEIPT_ID INT
AS
BEGIN
	DECLARE @REGION_ID INT,@TYLE_NGHIEM_THU_CUA_CHINH_PHAM FLOAT
	SELECT @REGION_ID = REGION_ID FROM base.VENDOR WHERE ID = (SELECT VENDOR_ID FROM wood.WH_RECEIPT WHERE ID = @RECEIPT_ID)
	SELECT  DLT.ID AS [CID],DLT.INPUT_TYPE_ID  ,DLT.ITEM_ID,TRIM(DLT.DTYPE) AS [DTYPE],DLT.PCS_PER_PACKAGE,
	DLT.PACKAGE_QUANTITY,DLT.PCS_PER_PACKAGE*DLT.PACKAGE_QUANTITY AS [TOTAL_QTY],
	DLT.SAMPLE_PACKAGE_QUANTITY,SAMPLE_QUANTITY,
	IPS.[RATE_A] AS [INS_RATE],wood.Func_Get_Pay_Rate(IPT.ID,
	1-CAST((SELECT SUM(DEFECT_QTY) FROM wood.WOOD_INSPECTION WHERE RECEIPT_ID=DLT.ID AND INPUT_TYPE_ID NOT IN(100017,100018,100019)) AS  float)/CAST(IPS.SAMPLE_QTY AS FLOAT)
	,DLT.ID,0,1) AS [PAY_RATE],
	IT.VOLUMN AS [ITEM_VOLUMN],
	ROUND((100 - ROUND(CAST((SELECT SUM(DEFECT_QTY) AS [DF_QTY] FROM wood.WOOD_INSPECTION 
		WHERE RECEIPT_ID =DLT.ID
		AND DEL_FLAG='N')  AS FLOAT)/CAST(IPS.[SAMPLE_QTY] AS FLOAT),4)*100)*IT.VOLUMN*DLT.PCS_PER_PACKAGE*DLT.PACKAGE_QUANTITY/100,4) AS [QC_VOLUMN],
	ROUND(IT.VOLUMN*DLT.PCS_PER_PACKAGE*DLT.PACKAGE_QUANTITY,4) AS [WH_VOLUMN],
	dbo.FUNC_GET_PRICE_WOOD((SELECT RECEIPT_DATE FROM wood.WH_RECEIPT WHERE ID = @RECEIPT_ID),DLT.ITEM_ID,TRIM(DLT.DTYPE),
	(SELECT REGION_ID FROM base.VENDOR WHERE ID = (SELECT VENDOR_ID FROM wood.WH_RECEIPT WHERE ID = @RECEIPT_ID)),DLT.INPUT_TYPE_ID,DLT.WTYPE,DLT.INPUT_TYPE_ID) AS [COM_PRICE],
	'INPUT' AS [ITYPE],0  AS [PARENTID],IPT.[NAME] AS [INPUT_NAME],IT.HEIGHT,IT.WIDTH,IT.LENGTH,
	IPS.SAMPLE_QTY-(SELECT SUM(DEFECT_QTY)  FROM wood.WOOD_INSPECTION WHERE RECEIPT_ID=DLT.ID AND DEL_FLAG='N') AS [GOOD_QTY],
	WT.NAME AS [WOOD_TYPE],DLT.WTYPE,DLT.ID AS [PID],IPS.[SAMPLE_QTY],IPS.[RATE_A],IPS.[RATE_B],IPS.[RATE_C],
	0 AS 'OUT_PRICE',
	1-CAST((SELECT SUM(DEFECT_QTY) FROM wood.WOOD_INSPECTION WHERE RECEIPT_ID=DLT.ID AND INPUT_TYPE_ID NOT IN(100017,100018,100019)) AS  float)/CAST(IPS.SAMPLE_QTY AS FLOAT) AS [TL]
FROM wood.WH_RECEIPT_DTL AS DLT
INNER JOIN base.ITEM AS IT ON IT.ID = DLT.ITEM_ID
INNER JOIN wood.WH_INPUT_TYPE AS IPT ON IPT.ID = DLT.INPUT_TYPE_ID
INNER JOIN wood.WOOD_TYPE AS WT ON WT.ID = DLT.WTYPE
INNER JOIN wood.WOOD_INSP AS IPS ON IPS.RECEIPT_ID = DLT.ID
WHERE DLT.[WH_RECEIPT_ID] =@RECEIPT_ID

UNION ALL
SELECT INS.ID-99999 AS [CID],INPUT_TYPE_ID,ITEM_ID,CASE WHEN HUMIDITY <=25 THEN 'K'  ELSE 'U' END AS [DTYPE],
0 AS [PCS_PER_PACKAGE],0 AS [PACKAGE_QUANTITY],0 AS [TOTAL_QTY],0 AS [SAMPLE_PACKAGE_QUANTITY],
0 AS [SAMPLE_QUANTITY],ROUND(CAST(INS.DEFECT_QTY AS FLOAT)/CAST((SELECT [SAMPLE_QTY] FROM wood.WOOD_INSP WHERE RECEIPT_ID=100001)AS FLOAT),4)*100 AS [INS_RATE],
wood.Func_Get_Pay_Rate(INS.INPUT_TYPE_ID,INS.PAY_RATE,INS.RECEIPT_ID,INS.ID,0) AS [PAY_RATE],IT.VOLUMN AS [ITEM_VOLUMN],
	ROUND(IT.VOLUMN*(SELECT PACKAGE_QUANTITY*PCS_PER_PACKAGE FROM wood.WH_RECEIPT_DTL WHERE ID = INS.RECEIPT_ID)*ROUND(CAST(DEFECT_QTY AS FLOAT)/CAST((SELECT [SAMPLE_QTY] FROM wood.WOOD_INSP WHERE RECEIPT_ID=100001)AS FLOAT),4) ,4)
	AS [QC_VOLUMN],
	0 AS [WH_VOLUMN],
	dbo.FUNC_GET_PRICE_WOOD((SELECT RECEIPT_DATE FROM wood.WH_RECEIPT WHERE ID =@RECEIPT_ID),INS.ITEM_ID,INS.DTYPE
	,@REGION_ID,INS.INPUT_TYPE_ID,INS.WTYPE,
	(SELECT INPUT_TYPE_ID FROM wood.WH_RECEIPT_DTL WHERE ID = RECEIPT_ID)) AS [COM_PRICE],
	'INSPECT' AS [ITYPE],RECEIPT_ID  AS [PARENTID],IPT.NAME AS [INPUT_NAME],IT.HEIGHT,IT.WIDTH,IT.LENGTH,INS.DEFECT_QTY AS [GOOD_QTY],
	WT.NAME AS [WOOD_TYPE],INS.WTYPE,INS.RECEIPT_ID AS [PID],-1 AS [SAMPLE_QTY],-1 AS [RATE_A],-1 AS [RATE_B],-1 AS [RATE_C],
	wood.Func_Get_Price_Of_Type(@REGION_ID,INS.INPUT_TYPE_ID,INS.PAY_RATE,INS.ID) AS 'OUT_PRICE',
	@TYLE_NGHIEM_THU_CUA_CHINH_PHAM AS [TL]
	FROM wood.WOOD_INSPECTION AS INS
	INNER JOIN base.ITEM AS IT ON IT.ID = INS.ITEM_ID
	INNER JOIN wood.WH_INPUT_TYPE AS IPT ON IPT.ID = INS.INPUT_TYPE_ID
	INNER JOIN wood.WOOD_TYPE AS WT ON WT.ID = INS.WTYPE
	WHERE RECEIPT_ID IN (SELECT ID FROM wood.WH_RECEIPT_DTL WHERE WH_RECEIPT_ID IN (SELECT ID FROM wood.WH_RECEIPT WHERE ID=@RECEIPT_ID)) 


END

GO
/****** Object:  StoredProcedure [wood].[Proc_Update_WH_Receipt]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create          PROC [wood].[Proc_Update_WH_Receipt] @ID  INT,@ALLOW_INSPECTION  BIT, @ALLOW_PAY  BIT,
@DEL_FLAG  NCHAR(10),@QC_STAFF  INT,@LOCK INT
AS
BEGIN  
	DECLARE @NEW_QC_STAFF AS INT,@NEW_ALLOW_INSPECTION AS BIT, @NEW_ALLOW_PAY AS BIT,@NEW_DEL_FLAG AS NCHAR(10),@RESULT AS BIT,@MESSAGE AS NVARCHAR(300)
	--SELECT @ID = WH_RECEIPT_ID FROM wood.WH_RECEIPT_DTL WHERE ID=@RECEIPT_DLT_ID
	SELECT @NEW_QC_STAFF= QC_STAFF,@NEW_DEL_FLAG=DEL_FLAG,@NEW_ALLOW_INSPECTION=ALLOW_INSPECTION,@NEW_ALLOW_PAY=ALLOW_PAY FROM wood.WH_RECEIPT WHERE ID=@ID
	IF @QC_STAFF IS NOT NULL
		SELECT @NEW_QC_STAFF = @QC_STAFF
	IF @ALLOW_INSPECTION IS NOT NULL
		SELECT @NEW_ALLOW_INSPECTION = @ALLOW_INSPECTION
	IF @ALLOW_PAY IS NOT NULL
		SET @NEW_ALLOW_PAY = @ALLOW_PAY
	IF @DEL_FLAG IS NOT NULL
		SET @NEW_DEL_FLAG = @DEL_FLAG
	BEGIN TRY
		UPDATE wood.WH_RECEIPT SET DEL_FLAG=@NEW_DEL_FLAG,ALLOW_INSPECTION=@NEW_ALLOW_INSPECTION,ALLOW_PAY= @NEW_ALLOW_PAY,QC_STAFF=@NEW_QC_STAFF,[LOCK] =@LOCK
		WHERE ID=@ID
		SELECT @RESULT=1,@MESSAGE=N'Thành công !'
	END TRY
	BEGIN CATCH
		SELECT @RESULT=0,@MESSAGE=ERROR_MESSAGE()
	END CATCH
	SELECT @RESULT AS [RESULT],@MESSAGE AS [MESSAGE],@ID AS [ID]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Update_WH_Receipt_Detail]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE            PROC [wood].[Proc_Update_WH_Receipt_Detail]
	@ID INT,@PCS_OF_QUANTITY INT,@PACKAGE_QUANTITY INT,@LEAVE BIT,@SAMPLE_QUANTITY INT,
	@SAMPLE_PACKAGE_QTY INT,@ITEM_ID INT,@NOTE NVARCHAR(300),@ITYPE INT,@DTYPE NVARCHAR(30),
	@UID INT
AS
BEGIN
	-- TAM THOI BO QUA KE HOACH
	DECLARE @NEW_PCS_PACKAGE_QTY INT,@NEW_PACKAGE_QTY INT,@NEW_LEAVE INT,@NEW_SAMPLE_QUANTITY INT,@NEW_SAMPLE_PACKAGE_QTY INT,
	@NEW_NOTE NVARCHAR(400),@NEW_RETURN_ID INT,@NEW_ITEM_ID INT,@NEW_ITYPE INT,@NEW_DTYPE INT

	IF @PCS_OF_QUANTITY IS NULL
		SELECT @NEW_PCS_PACKAGE_QTY = PCS_PER_PACKAGE  FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE
		SELECT @NEW_PCS_PACKAGE_QTY = @PCS_OF_QUANTITY

	IF @PACKAGE_QUANTITY IS NULL
		SELECT @NEW_PACKAGE_QTY = PACKAGE_QUANTITY FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE 
		SELECT @NEW_PACKAGE_QTY = @PACKAGE_QUANTITY
	IF @NOTE IS NULL
		SELECT @NEW_NOTE  = NOTE FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE
		SELECT @NEW_NOTE = @NOTE
	IF @ITEM_ID IS NULL
		SELECT @NEW_ITEM_ID = ITEM_ID FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE 
		SELECT @NEW_ITEM_ID = @ITEM_ID

	IF @LEAVE IS NULL
		SELECT @NEW_LEAVE = LEAVE FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE
		SELECT @NEW_LEAVE = @LEAVE
	IF @SAMPLE_PACKAGE_QTY IS NULL
		SELECT @SAMPLE_PACKAGE_QTY =  SAMPLE_PACKAGE_QUANTITY FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE 
		SELECT @NEW_SAMPLE_PACKAGE_QTY = @SAMPLE_PACKAGE_QTY

	IF @SAMPLE_QUANTITY IS NULL
		SELECT @NEW_SAMPLE_QUANTITY =  SAMPLE_QUANTITY FROM wood.WH_RECEIPT_DTL WHERE ID= @ID
	ELSE 
		SELECT @NEW_SAMPLE_QUANTITY = @SAMPLE_QUANTITY

	UPDATE wood.WH_RECEIPT_DTL
	SET [ITEM_ID]=@NEW_ITEM_ID,[PCS_PER_PACKAGE]=@NEW_PCS_PACKAGE_QTY,
	[NOTE]=@NEW_NOTE,[SAMPLE_PACKAGE_QUANTITY]=@NEW_SAMPLE_PACKAGE_QTY,[LEAVE]=@NEW_LEAVE,
	[SAMPLE_QUANTITY] =@NEW_SAMPLE_QUANTITY,[MODIFY_AT]=GETDATE(),[MODIFY_BY]=@UID,
	[PACKAGE_QUANTITY]=@NEW_PACKAGE_QTY,DTYPE=@DTYPE,INPUT_TYPE_ID=@ITYPE
	WHERE [ID]=@ID
	SELECT 1 AS [RESULT],N'Thành Công !' AS [MESSAGE]
END
GO
/****** Object:  StoredProcedure [wood].[Proc_Update_Wood_InSpection]    Script Date: 5/19/2021 1:34:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create         PROC [wood].[Proc_Update_Wood_InSpection]
	@ID INT,@INPUT_TYPE_ID INT,@ITEM_ID INT,@NOTE NVARCHAR(300),@SIZE_OUT_RATE FLOAT,@ISDOUBLE NCHAR(10),@UID INT
AS
BEGIN
	DECLARE @NEW_INPUT_TYPE_ID INT,@NEW_ITEM_ID INT,@NEW_NOTE NVARCHAR(400),@NEW_SIZE_OUT_RATE FLOAT,@NEW_ISDOUBLE NCHAR(10) 
	
	SELECT @NEW_INPUT_TYPE_ID = INPUT_TYPE_ID,@NEW_ITEM_ID = ITEM_ID,@NEW_NOTE = NOTE,@SIZE_OUT_RATE=SIZE_OUT_RATE,@NEW_ISDOUBLE=IS_DOUBLE FROM wood.WOOD_INSPECTION WHERE ID=@ID


	IF @INPUT_TYPE_ID IS NULL
		SELECT @NEW_INPUT_TYPE_ID = @INPUT_TYPE_ID
	IF @NOTE IS NULL
		SELECT @NEW_NOTE  = @NOTE
	IF @SIZE_OUT_RATE IS NULL
		SELECT @NEW_SIZE_OUT_RATE = @SIZE_OUT_RATE
	IF @ISDOUBLE IS NULL
		SELECT @NEW_ISDOUBLE = @ISDOUBLE
	UPDATE wood.[WOOD_INSPECTION] SET INPUT_TYPE_ID=@NEW_INPUT_TYPE_ID,ITEM_ID=@NEW_ITEM_ID,SIZE_OUT_RATE=@NEW_SIZE_OUT_RATE,IS_DOUBLE=@NEW_ISDOUBLE,NOTE = @NOTE,
	UPDATE_AT=GETDATE(),UPDATE_BY=@UID
	WHERE ID = @ID

	SELECT 1 AS [RESULT],N'Thành công !' AS [MESSAGE]
END
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "mip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 243
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 281
               Bottom = 136
               Right = 451
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 232
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 138
               Left = 270
               Bottom = 268
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiDat100026s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiDat100026s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiDat100026s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "mip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 243
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 281
               Bottom = 136
               Right = 451
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 232
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 138
               Left = 270
               Bottom = 268
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         O' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiLoi100004s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'utput = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiLoi100004s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_GhiLoi100004s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[37] 4[16] 2[29] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 6
               Left = 262
               Bottom = 219
               Right = 472
            End
            DisplayFlags = 280
            TopColumn = 11
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 510
               Bottom = 136
               Right = 725
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 3330
         Width = 3390
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_NhapVe100026s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_NhapVe100026s'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[49] 4[12] 2[13] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "BOM (prod)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Bom'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Bom'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "x"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_conthuchien'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_conthuchien'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[21] 4[11] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 226
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 263
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 5
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 3645
         Width = 3510
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_DatKeHoach'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_DatKeHoach'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[14] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "DEPARTMENT (base)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 287
               Right = 270
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Departments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Departments'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[47] 4[4] 2[24] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 185
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 192
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 478
               Bottom = 192
               Right = 677
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 72
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
     ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_GhiNhanCT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'    Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 3060
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_GhiNhanCT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_GhiNhanCT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ITEM_IN_PALLET (prod)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ITEM (base)"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 136
               Right = 419
            End
            DisplayFlags = 280
            TopColumn = 4
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ITEM_IN_PALLET'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ITEM_IN_PALLET'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[43] 4[32] 2[4] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ITEM (base)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 263
               Right = 211
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ITEM_TYPE (base)"
            Begin Extent = 
               Top = 6
               Left = 249
               Bottom = 220
               Right = 419
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "UNIT (base)"
            Begin Extent = 
               Top = 6
               Left = 457
               Bottom = 215
               Right = 627
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 29
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         App' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ITEM100002'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'end = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ITEM100002'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ITEM100002'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[27] 4[19] 2[35] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "x"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 220
               Right = 445
            End
            DisplayFlags = 280
            TopColumn = 15
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 13
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 6165
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ItemInPackages'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ItemInPackages'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[23] 4[38] 2[8] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ITEM (base)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 211
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Items'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[32] 4[3] 2[43] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "mip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 259
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 297
               Bottom = 136
               Right = 483
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 6
               Left = 521
               Bottom = 285
               Right = 731
            End
            DisplayFlags = 280
            TopColumn = 5
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 769
               Bottom = 136
               Right = 984
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Materials_Package_100026_100004'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Materials_Package_100026_100004'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "P"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 248
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IIP"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "D"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 286
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GD"
            Begin Extent = 
               Top = 138
               Left = 262
               Bottom = 268
               Right = 448
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_NHAP_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_NHAP_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[34] 4[3] 2[44] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 6
               Left = 262
               Bottom = 335
               Right = 472
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 510
               Bottom = 136
               Right = 725
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Package_100026'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Package_100026'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "i"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 233
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 11
               Left = 790
               Bottom = 240
               Right = 984
            End
            DisplayFlags = 280
            TopColumn = 8
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 126
               Left = 368
               Bottom = 256
               Right = 600
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "bi"
            Begin Extent = 
               Top = 11
               Left = 238
               Bottom = 282
               Right = 411
            End
            DisplayFlags = 280
            TopColumn = 6
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 23
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PackageDepartment'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PackageDepartment'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PackageDepartment'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[37] 4[21] 2[23] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PALLET_CHO_XAY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PALLET_CHO_XAY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[16] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PhoiNhan'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_PhoiNhan'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[15] 4[4] 2[37] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 24
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_raw_data'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_raw_data'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[27] 4[4] 2[35] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 14
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_raw_nhap_ton'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_raw_nhap_ton'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[7] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 270
               Right = 223
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 261
               Bottom = 136
               Right = 493
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "i"
            Begin Extent = 
               Top = 6
               Left = 531
               Bottom = 136
               Right = 704
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Routing'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Routing'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ROUTING (prod)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 223
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Routings'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Routings'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[63] 4[4] 2[15] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "pa"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 136
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 11
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 35
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 270
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 138
               Left = 275
               Bottom = 268
               Right = 445
            End
            DisplayFlags = 280
            TopColumn = 3
         End
         Begin Table = "i"
            Begin Extent = 
               Top = 402
               Left = 38
               Bottom = 532
               Right = 211
            End
            DisplayFlags = 280
            TopColumn = 14
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SanLuong'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'        Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SanLuong'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SanLuong'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS1A'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS1A'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS1B'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS1B'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ACCEPT (fpm)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS4'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_SP_YS4'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[13] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 136
               Right = 478
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "i"
            Begin Extent = 
               Top = 6
               Left = 516
               Bottom = 136
               Right = 689
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThieuPhoi'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThieuPhoi'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[12] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 232
            End
            DisplayFlags = 280
            TopColumn = 8
         End
         Begin Table = "v"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 14
         End
         Begin Table = "I"
            Begin Extent = 
               Top = 6
               Left = 270
               Bottom = 136
               Right = 443
            End
            DisplayFlags = 280
            TopColumn = 14
         End
         Begin Table = "po"
            Begin Extent = 
               Top = 6
               Left = 481
               Bottom = 136
               Right = 680
            End
            DisplayFlags = 280
            TopColumn = 35
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 718
               Bottom = 136
               Right = 950
            End
            DisplayFlags = 280
            TopColumn = 12
         End
         Begin Table = "i2"
            Begin Extent = 
               Top = 6
               Left = 988
               Bottom = 136
               Right = 1161
            End
            DisplayFlags = 280
            TopColumn = 14
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 17
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThongTinTruyNguyen'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'= 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThongTinTruyNguyen'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThongTinTruyNguyen'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[31] 4[3] 2[11] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 233
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 39
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 275
               Bottom = 102
               Right = 445
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "M"
            Begin Extent = 
               Top = 6
               Left = 483
               Bottom = 136
               Right = 653
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 37
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin Cr' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThucHienKeHoach'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'iteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThucHienKeHoach'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_ThucHienKeHoach'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "TON"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TON_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TON_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[20] 4[10] 2[43] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "i"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 227
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "OS"
            Begin Extent = 
               Top = 6
               Left = 265
               Bottom = 136
               Right = 435
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "B"
            Begin Extent = 
               Top = 6
               Left = 473
               Bottom = 136
               Right = 643
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TonDauKy'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TonDauKy'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[22] 4[22] 2[37] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "iip"
            Begin Extent = 
               Top = 6
               Left = 281
               Bottom = 136
               Right = 451
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 489
               Bottom = 136
               Right = 683
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TongGhiNhanSL'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_TongGhiNhanSL'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "P"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 248
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IIP"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "D"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 286
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GD"
            Begin Extent = 
               Top = 138
               Left = 262
               Bottom = 268
               Right = 448
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_XUAT_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_XUAT_QC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[9] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 3390
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_BOM'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_BOM'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[25] 4[4] 2[8] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "pnk"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 322
               Right = 210
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pn"
            Begin Extent = 
               Top = 12
               Left = 292
               Bottom = 373
               Right = 472
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 24
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_PHIEUNHAPKHO_DT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_PHIEUNHAPKHO_DT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[3] 2[38] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PLAN_NLG"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 249
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PROVIDERS"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 136
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GROUP_CODE"
            Begin Extent = 
               Top = 6
               Left = 454
               Bottom = 102
               Right = 624
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_PLAN_NLG'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'nlg', @level1type=N'VIEW',@level1name=N'View_PLAN_NLG'
GO
