create or replace 
PACKAGE  XX_SO_SHIP_PKG AS

PROCEDURE MAIN 
(
p_organization_id IN NUMBER,
p_sales_order_num IN Number,
x_return_status OUT VARCHAR2,
x_ret_message OUT VARCHAR2
);

END;