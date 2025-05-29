-- Case Study 1: Phân Tích Hiệu Suất Bán Hàng (Sales Performance Analysis)
-- 1.	Doanh thu theo khu vực: o	Tính tổng doanh thu (TotalDue) của từng khu vực (Territory) trong năm 2013

SELECT 
        YEAR(OrderDate) Year_Fiscal,
        TerritoryID,
        SUM(TotalDue) TotalRevenue
FROM Sales.SalesOrderHeader 
WHERE YEAR(OrderDate) = 2013
GROUP BY TerritoryID, YEAR(OrderDate);

-- 2.	Hiệu suất theo sản phẩm:o	Tìm 5 sản phẩm bán chạy nhất trong từng danh mục (ProductCategory) trong năm 2013 (dựa trên doanh thu).
WITH Ranking_Total AS
(
    SELECT 
        YEAR(SOH.OrderDate) Year_Fiscal, 
        SOD.ProductID, 
        P.Name Product_Name,
        PC.Name ProductCategory_Name,
        Sum(TotalDue) TotalRevenue,
        RANK() OVER (PARTITION BY PC.Name ORDER BY Sum(TotalDue) DESC) Ranking
    FROM Sales.SalesOrderDetail SOD
    LEFT JOIN Sales.SalesOrderHeader SOH
        ON SOD.SalesOrderID = SOH.SalesOrderID
    LEFT JOIN Production.Product P
        ON SOD.ProductID = P.ProductID
    LEFT JOIN Production.ProductSubcategory PS
    ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory PC
    ON PS.ProductCategoryID = PC.ProductCategoryID
    Where YEAR(SOH.OrderDate) = 2013
    GROUP BY YEAR(SOH.OrderDate), SOD.ProductID, P.Name,PC.Name
)
SELECT *
FROM Ranking_Total
Where Ranking <6 
ORDER BY ProductCategory_Name, Ranking

-- 3.	Hiệu suất theo khách hàng:o	Xác định khách hàng nào có tổng chi tiêu cao nhất theo từng tháng trong năm 2013.

WITH Ranking_MonthTotal as
(
    SELECT 
            YEAR(OrderDate) Year_Fiscal,
            MONTH(OrderDate) Month_Fiscal,
            CustomerID,
            Sum(TotalDue) TotalRevenue,
            RANK() OVER (PARTITION BY MONTH(OrderDate) ORDER BY Sum(TotalDue) DESC) Ranking
    FROM Sales.SalesOrderHeader
    Where YEAR(OrderDate) = 2013
    GROUP by YEAR(OrderDate), MONTH(OrderDate),  CustomerID
)
SELECT *
FROM Ranking_MonthTotal
Where Ranking = 1;

-- 4.	Xu hướng doanh thu: o	Tìm chênh lệch doanh thu từng tháng trong năm 2013.

SELECT 
    YEAR(OrderDate) Year_Fiscal,
    MONTH(OrderDate) Month_Fiscal,
    SUM(TotalDue) TotalRevenue,
    LAG(SUM(TotalDue)) OVER(ORDER by MONTH(OrderDate)) Lag_Revenue,
    SUM(TotalDue) - LAG(SUM(TotalDue)) OVER(ORDER by MONTH(OrderDate)) Revenue_Diff
FROM Sales.SalesOrderHeader
Where YEAR(OrderDate) = 2013
GROUP by YEAR(OrderDate),  MONTH(OrderDate)

-- 5.	Hiệu suất bán hàng theo nhân viên:
-- o	Tính doanh thu mà mỗi nhân viên bán hàng (SalesPerson) đóng góp trong năm 2013.

SELECT 
    YEAR(OrderDate) Year_Fiscal,
    SalesPersonID,
    SUM(TotalDue) TotalRevenue
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
AND YEAR(OrderDate) = 2013
GROUP BY YEAR(OrderDate), SalesPersonID

-- o	Xếp hạng nhân viên theo doanh thu (từ cao xuống thấp).

SELECT 
    YEAR(OrderDate) Year_Fiscal,
    SalesPersonID,
    SUM(TotalDue) TotalRevenue,
    RANK() OVER (ORDER BY Sum(TotalDue) DESC) Ranking
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
AND YEAR(OrderDate) = 2013
GROUP BY YEAR(OrderDate), SalesPersonID

-- Case Study 2: Phân Tích Hiệu Quả Nhân Sự
-- 1.	Phân bổ nhân sự:
-- o	Tính tổng số lượng nhân viên hiện tại trong từng phòng ban.

SELECT 
    DepartmentID,
    COUNT(BusinessEntityID) TotalEmployee
FROM HumanResources.EmployeeDepartmentHistory
Where EndDate IS NULL
GROUP by DepartmentID;


-- o	Xác định phòng ban nào có số lượng nhân viên ít nhất.

WITH Ranking_Employee As
(
SELECT 
    DepartmentID,
    COUNT(BusinessEntityID) TotalEmployee,
    RANK() OVER (ORDER BY COUNT(BusinessEntityID) ASC) Ranking
FROM HumanResources.EmployeeDepartmentHistory
Where EndDate IS NULL
GROUP by DepartmentID
)
SELECT *
from Ranking_Employee
Where Ranking = 1

-- 2.	Thâm niên (giả định thâm niên tính tới năm 2015):
-- o	Liệt kê danh sách 5 nhân viên có thâm niên cao nhất trong công ty.

WITH Ranking_Seniority as
(
    SELECT 
        ED.BusinessEntityID,
        CONCAT(Title, FirstName) Employee_Name,
        E.JobTitle Job_Name,
        D.Name Department_Name,
        DATEDIFF(YEAR,ed.StartDate,'2015-01-01') Seniority,
        RANK() OVER (ORDER BY DATEDIFF(YEAR,ed.StartDate,'2015-01-01') DESC) Ranking
    FROM HumanResources.EmployeeDepartmentHistory ED
    LEFT JOIN HumanResources.Employee E
    ON ED.BusinessEntityID = e.BusinessEntityID
    LEFT JOIN HumanResources.Department D
    ON ED.DepartmentID = d.DepartmentID
    LEFT JOIN Person.Person P
    ON ed.BusinessEntityID = p.BusinessEntityID
    Where ed.EndDate is NULL
)
SELECT *
from Ranking_Seniority
WHERE Ranking < 6

-- 3.	Phân bố chức danh:
-- o	Đếm số lượng nhân viên cho mỗi chức danh công việc (Job Title) trong toàn công ty.

SELECT 
    E.JobTitle Job_Name,
    COUNT(ED.BusinessEntityID) TotalEmployee
FROM HumanResources.EmployeeDepartmentHistory ED
LEFT JOIN HumanResources.Employee E
ON ED.BusinessEntityID = E.BusinessEntityID
Where EndDate IS NULL
GROUP by  E.JobTitle;

-- o	Tìm chức danh có nhiều nhân viên nhất và ít nhân viên nhất.
WITH COUNT_Job as 
(
    SELECT 
    E.JobTitle Job_Name,
    COUNT(ED.BusinessEntityID) TotalEmployee
    FROM HumanResources.EmployeeDepartmentHistory ED
    LEFT JOIN HumanResources.Employee E
    ON ED.BusinessEntityID = E.BusinessEntityID
    Where EndDate IS NULL
    GROUP by  E.JobTitle
)
select *
from COUNT_Job
Where TotalEmployee = (select Max(TotalEmployee) FROM COUNT_Job) or TotalEmployee = (select Min(TotalEmployee) FROM COUNT_Job)
