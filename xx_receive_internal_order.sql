create or replace 
procedure xx_receive_internal_order(p_req_id IN NUMBER) IS
--declare

L_RCV_HEADER_ID      NUMBER;
L_RCV_GROUP_ID       NUMBER;
L_RCV_TRANSACTION_ID NUMBER;
ln_user_id           NUMBER;
ln_resp_id           NUMBER;
ln_app_id            NUMBER;
lv_request_id        NUMBER;
CURSOR c_ship_h_data IS
Select rsh.RECEIPT_SOURCE_CODE, 
       rsh.SHIPMENT_NUM,
       rsh.employee_id,
       rsl.shipment_line_id,
       rsh.shipment_header_id,
       rl.requisition_line_id,
       rsl.req_distribution_id,
       rsl.primary_unit_of_measure,
       rl.item_id,
       rsl.deliver_to_person_id,
       rsl.TO_ORGANIZATION_ID SHIP_TO_ORGANIZATION_ID,
       rsl.TO_ORGANIZATION_ID,
       rl.SOURCE_SUBINVENTORY subinventory,
       rsl.deliver_to_location_id,
       rsl.source_document_code,
       rsh.ship_to_location_id,
       rl.quantity,
       rl.org_id
from rcv_shipment_headers rsh,
rcv_shipment_lines rsl,
po_requisition_lines_all rl
where rsl.shipment_header_id = rsh.shipment_header_id
and rsl.requisition_line_id = rl.requisition_line_id
AND REQUISITION_HEADER_ID = p_req_id;
 


BEGIN


FOR rec_ship_h_data IN c_ship_h_data LOOP

SELECT RCV_HEADERS_INTERFACE_S.NEXTVAL  "L_RCV_HEADER_ID"
  INTO L_RCV_HEADER_ID
FROM DUAL;

SELECT RCV_INTERFACE_GROUPS_S.NEXTVAL  "L_RCV_GROUP_ID"
  INTO L_RCV_GROUP_ID
FROM DUAL;  
 
SELECT rcv_transactions_interface_s.NEXTVAL "L_RCV_TRANSACTION_ID"
INTO L_RCV_TRANSACTION_ID
FROM DUAL;

 INSERT INTO RCV_HEADERS_INTERFACE
(HEADER_INTERFACE_ID,
GROUP_ID,
PROCESSING_STATUS_CODE,
RECEIPT_SOURCE_CODE,
TRANSACTION_TYPE,
AUTO_TRANSACT_CODE,
LAST_UPDATE_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_LOGIN,
CREATION_DATE,
CREATED_BY,
SHIPMENT_NUM,
SHIP_TO_ORGANIZATION_ID,
EXPECTED_RECEIPT_DATE,
SHIPPED_DATE,
EMPLOYEE_ID,
VALIDATION_FLAG
)
VALUES
(L_RCV_HEADER_ID , --HEADER_INTERFACE_ID
L_RCV_GROUP_ID, --GROUP_ID
'PENDING', --PROCESSING_STATUS_CODE
'INTERNAL ORDER', --RECEIPT_SOURCE_CODE
'NEW', --TRANSACTION_TYPE
'DELIVER', --AUTO_TRANSACT_CODE
SYSDATE, --LAST_UPDATE_DATE
0, --LAST_UPDATE_BY
0, --LAST_UPDATE_LOGIN
SYSDATE, --CREATION_DATE
0, --CREATED_BY
rec_ship_h_data.SHIPMENT_NUM, --SHIPMENT_NUM
rec_ship_h_data.SHIP_TO_ORGANIZATION_ID,
SYSDATE+1, --EXPECTED_RECEIPT_DATE
SYSDATE, --SHIPPED_DATE
rec_ship_h_data.employee_id, --EMPLOYEE_ID
'Y' --VALIDATION_FLAG
);
INSERT INTO RCV_TRANSACTIONS_INTERFACE
(INTERFACE_TRANSACTION_ID,
GROUP_ID,
LAST_UPDATE_DATE,
LAST_UPDATED_BY,
CREATION_DATE,
CREATED_BY,
LAST_UPDATE_LOGIN,
TRANSACTION_TYPE,
TRANSACTION_DATE,
PROCESSING_STATUS_CODE,
PROCESSING_MODE_CODE,
TRANSACTION_STATUS_CODE,
QUANTITY,
UNIT_OF_MEASURE,
INTERFACE_SOURCE_CODE,
ITEM_ID,
EMPLOYEE_ID,
AUTO_TRANSACT_CODE,
SHIPMENT_HEADER_ID,
SHIPMENT_LINE_ID,
SHIP_TO_LOCATION_ID,
RECEIPT_SOURCE_CODE,
TO_ORGANIZATION_ID,
SOURCE_DOCUMENT_CODE,
REQUISITION_LINE_ID,
REQ_DISTRIBUTION_ID,
DESTINATION_TYPE_CODE,
DELIVER_TO_PERSON_ID,
LOCATION_ID,
DELIVER_TO_LOCATION_ID,
SUBINVENTORY,
SHIPMENT_NUM,
EXPECTED_RECEIPT_DATE,
SHIPPED_DATE,
HEADER_INTERFACE_ID,
VALIDATION_FLAG,
ORG_ID
)
VALUES
( L_RCV_TRANSACTION_ID, -- INTERFACE_TRANSACTION_ID
L_RCV_GROUP_ID, --GROUP_ID
SYSDATE, --LAST_UPDATE_DATE
0, --LAST_UPDATED_BY
SYSDATE, --CREATION_DATE
0, --CREATED_BY
0, --LAST_UPDATE_LOGIN
'RECEIVE', --TRANSACTION_TYPE
SYSDATE, --TRANSACTION_DATE
'PENDING', --PROCESSING_STATUS_CODE
'BATCH', --PROCESSING_MODE_CODE
'PENDING', --TRANSACTION_STATUS_CODE
rec_ship_h_data.quantity, --QUANTITY
rec_ship_h_data.primary_unit_of_measure, --UNIT_OF_MEASURE
'RCV', --INTERFACE_SOURCE_CODE
rec_ship_h_data.item_id, --ITEM_ID
rec_ship_h_data.EMPLOYEE_ID, --EMPLOYEE_ID
'DELIVER', --AUTO_TRANSACT_CODE
rec_ship_h_data.SHIPMENT_HEADER_ID,
rec_ship_h_data.SHIPMENT_LINE_ID,
rec_ship_h_data.SHIP_TO_LOCATION_ID,
'INTERNAL ORDER', --RECEIPT_SOURCE_CODE
rec_ship_h_data.TO_ORGANIZATION_ID,
rec_ship_h_data.SOURCE_DOCUMENT_CODE,
rec_ship_h_data.REQUISITION_LINE_ID,
rec_ship_h_data.REQ_DISTRIBUTION_ID,
'INVENTORY', --DESTINATION_TYPE_CODE
rec_ship_h_data.DELIVER_TO_PERSON_ID,
null, --LOCATION_ID
rec_ship_h_data.DELIVER_TO_LOCATION_ID,
rec_ship_h_data.SUBINVENTORY,
rec_ship_h_data.SHIPMENT_NUM,
SYSDATE+1, --EXPECTED_RECEIPT_DATE,
SYSDATE, --SHIPPED_DATE
L_RCV_HEADER_ID, --HEADER_INTERFACE_ID
'Y' --VALIDATION_FLAG
,rec_ship_h_data.org_id
);
commit;
dbms_output.put_line('Batch Id '||rcv_interface_groups_s.currval);

END LOOP;

BEGIN
SELECT user_id 
INTO ln_user_id
FROM fnd_user 
WHERE user_name = 'SYSADMIN';

SELECT responsibility_id,application_id
  INTO ln_resp_id,ln_app_id
from fnd_responsibility_tl where responsibility_name ='Purchasing, Vision Operations (USA)';


EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line('Error while fetchinh user_id');
END;

fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_app_id);

    -- Submitting XX_PROGRAM_1;
      lv_request_id := fnd_request.submit_request ( 
                            application   => 'PO', 
                            program       => 'RVCTP', 
                            description   => null, 
                            start_time    => sysdate, 
                            sub_request   => FALSE,
                            argument1     =>'BATCH',
                            argument2      =>L_RCV_GROUP_ID);
   COMMIT;


END;