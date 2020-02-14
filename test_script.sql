set serveroutput on;
declare

lv_srroe   VARCHAR2(2000);
lv_message  VARCHAR2(2000);
lv_req_number  VARCHAR2(200);
lv_order       VARCHAR2(200);
ln_request_id  NUMBER;
ln_req_id      NUMBER;
lv_srroe_1   VARCHAR2(2000);
lv_message_1  VARCHAR2(2000);
lv_PHASE_CODE VARCHAR2(200);
lv_STATUS_CODE VARCHAR2(200);
lv_curr_date date;
lv_start_date date;
begin

XX_REQ_CREATE_PKG.create_int_req(p_source_org =>'M1'
                                ,p_destination_org =>'M2'
                                ,p_item_number =>'75100023'
                                ,p_transfer_quantity =>1
                                ,p_source_subinventory =>'FGI'
                                ,p_dest_subinventory =>'FGI'
                                ,x_request_id =>ln_request_id
                                ,x_status =>lv_srroe_1
                                ,x_message =>lv_message_1);
DBMS_OUTPUT.PUT_LINE('lv_srroe_1 '||lv_srroe_1);
DBMS_OUTPUT.PUT_LINE('lv_message_1 '||lv_message_1);
DBMS_OUTPUT.PUT_LINE('ln_request_id '||ln_request_id);
WHILE ((lv_PHASE_CODE not in ('C','W')) AND (lv_STATUS_CODE NOT IN ('C','W'))) 
LOOP

select PHASE_CODE, STATUS_CODE
INTO lv_PHASE_CODE, lv_STATUS_CODE
FROM fnd_conc_req_summary_v
WHERE request_id = ln_request_id;

END LOOP;

--IF lv_PHASE_CODE = 'C' AND lv_STATUS_CODE = 'C' THEN

lv_curr_date := sysdate;
lv_start_date := sysdate;
while lv_req_number IS NULL OR (lv_curr_date-lv_start_date)*24*60 <3
LOOP
begin

	SELECT segment1,requisition_header_id 
	  INTO lv_req_number,ln_req_id
	  FROM po_requisition_headers_all
	 WHERE request_id = ln_request_id
     AND type_lookup_code = 'INTERNAL';

select order_number into lv_order
from oe_order_headers_all
where orig_sys_document_ref = lv_req_number;
EXCEPTION WHEN OTHERS THEN
lv_order := NULL;
end;
lv_curr_date := sysdate;
END LOOP;

IF lv_order IS NOT NULL THEN
XX_SO_SHIP_PKG.main(NULL,lv_order,lv_srroe,lv_message);

xx_receive_internal_order(ln_req_id);

DBMS_OUTPUT.PUT_LINE('lv_srroe '||lv_srroe);
DBMS_OUTPUT.PUT_LINE('lv_message '||lv_message);
END IF;
--END IF;
end;