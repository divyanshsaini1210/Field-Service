create or replace 
PACKAGE XX_REQ_CREATE_PKG AS

gn_batch_id NUMBER;


PROCEDURE create_int_req( p_source_org IN VARCHAR2
                          ,p_destination_org IN VARCHAR2
                          ,p_item_number IN VARCHAR2
                          ,p_transfer_quantity IN VARCHAR2
						              ,p_source_subinventory IN VARCHAR2
                          ,p_dest_subinventory IN VARCHAR2
                          ,x_request_id OUT NUMBER
                          ,x_status OUT VARCHAR2
                          ,x_message OUT VARCHAR2);
                          
END XX_REQ_CREATE_PKG;