create or replace 
PACKAGE BODY XX_REQ_CREATE_PKG AS


PROCEDURE submit_create_order(x_wr_phase OUT VARCHAR2,x_wr_status OUT VARCHAR2) IS
ln_request_id NUMBER DEFAULT 0;
lv_PHASE_CODE VARCHAR2(200);
lv_STATUS_CODE VARCHAR2(200);
l_sc_phase           VARCHAR2(100);
l_sc_status          VARCHAR2(100);
l_sc_dev_phase       VARCHAR2(100);
l_sc_dev_status      VARCHAR2(100);
l_sc_message         VARCHAR2(4000);
l_wr_output          BOOLEAN;
BEGIN

ln_request_id := apps.fnd_request.submit_request (
                      application  =>  'PO'
                     ,program      =>  'POCISO'
                     ,description  =>  'Create Internal Orders'
                     ,start_time   =>  SYSDATE
                     ,sub_request  =>  NULL
			  );
commit;
        l_sc_phase        := NULL;
        l_sc_status       := NULL;
        l_sc_dev_phase    := NULL;
        l_sc_dev_status   := NULL;
        l_sc_message      := NULL;
        BEGIN
          l_wr_output := fnd_concurrent.wait_for_request(
                                                         request_id => ln_request_id
                                                        ,INTERVAL   => 10
                                                        ,max_wait   => 0
                                                        ,phase      => l_sc_phase
                                                        ,status     => l_sc_status
                                                        ,dev_phase  => l_sc_dev_phase
                                                        ,dev_status => l_sc_dev_status
                                                        ,message    => l_sc_message
                                                        );
        END;


x_wr_phase:= l_sc_phase;
x_wr_status :=l_sc_status;
dbms_output.put_line('request Id '||ln_request_id);
EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line('Error while submitting program');
END;

PROCEDURE submit_order_import(p_req_number IN VARCHAR2) IS

v_request_id                        NUMBER           DEFAULT 0;
    
    --Order Import Parameters
    p_operation_code                     VARCHAR2(20)    := NULL;
    p_validate_only                      VARCHAR2(20)    := 'N';
    p_debug_level                        VARCHAR2(20)    := '1';
    p_num_instances                      VARCHAR2(20)    := '4';
    p_sold_to_org_id                     VARCHAR2(20)    := NULL;
    p_sold_to_org                        VARCHAR2(20)    := NULL;
    p_change_sequence                    VARCHAR2(20)    := NULL;
    p_perf_param                         VARCHAR2(20)    := 'Y';
    p_rtrim_data                         VARCHAR2(20)    := 'N';
    p_pro_ord_with_null_flag             VARCHAR2(20)    := 'Y';
    p_validate_desc_flex                 VARCHAR2(20)    := 'N';
	ln_user_id                           NUMBER;
	ln_resp_id                           NUMBER;
	ln_app_id                            NUMBER;
l_sc_phase           VARCHAR2(100);
l_sc_status          VARCHAR2(100);
l_sc_dev_phase       VARCHAR2(100);
l_sc_dev_status      VARCHAR2(100);
l_sc_message         VARCHAR2(4000);
l_wr_output          BOOLEAN;
BEGIN

BEGIN
SELECT user_id 
INTO ln_user_id
FROM fnd_user 
WHERE user_name = 'SYSADMIN';

SELECT responsibility_id,application_id
  INTO ln_resp_id,ln_app_id
from fnd_responsibility_tl where responsibility_name ='Order Management Super User, Vision Operations (USA)';


EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line('Error while fetchinh user_id');
END;

fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_app_id);

v_request_id:=  FND_REQUEST.SUBMIT_REQUEST (
               application  =>  'ONT'
              ,program      =>  'OEOIMP'
              ,description  =>  'Order Import'
              ,start_time   =>  SYSDATE
              ,sub_request  =>  NULL
              ,argument1    =>  NULL
              ,argument2    =>  10
              ,argument3    =>  p_req_number
              ,argument4    =>  p_operation_code
              ,argument5    =>  p_validate_only
              ,argument6    =>  p_debug_level
              ,argument7    =>  p_num_instances
              ,argument8    =>  p_sold_to_org_id
              ,argument9    =>  p_sold_to_org
              ,argument10   =>  p_change_sequence
              ,argument11   =>  p_perf_param
              ,argument12   =>  p_rtrim_data
              ,argument13   =>  p_pro_ord_with_null_flag
              ,argument14   =>  NUll
              ,argument15   =>  p_validate_desc_flex
             );

       COMMIT;

        l_sc_phase        := NULL;
        l_sc_status       := NULL;
        l_sc_dev_phase    := NULL;
        l_sc_dev_status   := NULL;
        l_sc_message      := NULL;
        BEGIN
          l_wr_output := fnd_concurrent.wait_for_request(
                                                         request_id => v_request_id
                                                        ,INTERVAL   => 10
                                                        ,max_wait   => 0
                                                        ,phase      => l_sc_phase
                                                        ,status     => l_sc_status
                                                        ,dev_phase  => l_sc_dev_phase
                                                        ,dev_status => l_sc_dev_status
                                                        ,message    => l_sc_message
                                                        );
        END;


--x_wr_phase:= l_sc_phase;
--x_wr_status :=l_sc_status;
dbms_output.put_line('Request Id '||v_request_id);
EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line('Error while submitting program'); 	   
END;

PROCEDURE submit_req_import_concurrent (x_wr_phase OUT VARCHAR2,x_wr_status  OUT VARCHAR2,x_request_id OUT NUMBER) IS

ln_user_id NUMBER;
ln_resp_id NUMBER;
ln_app_id  NUMBER;
ln_request_id NUMBER;
l_sc_phase           VARCHAR2(100);
l_sc_status          VARCHAR2(100);
l_sc_dev_phase       VARCHAR2(100);
l_sc_dev_status      VARCHAR2(100);
l_sc_message         VARCHAR2(4000);
l_wr_output          BOOLEAN;
BEGIN

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

ln_request_id := apps.fnd_request.submit_request (application => 'PO' --Application,
,program => 'REQIMPORT' --Program,
,argument1 => 'INT' --Interface Source code,
,argument2 => '' --Batch ID,
,argument3 => ''--Group By,
,argument4 => ''--Last Req Number,
,argument5 => ''--Multi Distributions,
,argument6 => 'N' --Initiate Approval after ReqImport
);
commit;

        l_sc_phase        := NULL;
        l_sc_status       := NULL;
        l_sc_dev_phase    := NULL;
        l_sc_dev_status   := NULL;
        l_sc_message      := NULL;
        BEGIN
          l_wr_output := fnd_concurrent.wait_for_request(
                                                         request_id => ln_request_id
                                                        ,INTERVAL   => 10
                                                        ,max_wait   => 0
                                                        ,phase      => l_sc_phase
                                                        ,status     => l_sc_status
                                                        ,dev_phase  => l_sc_dev_phase
                                                        ,dev_status => l_sc_dev_status
                                                        ,message    => l_sc_message
                                                        );
        END;


x_wr_phase:= l_sc_phase;
x_wr_status :=l_sc_status;
x_request_id:= ln_request_id;
EXCEPTION WHEN OTHERS THEN
   dbms_output.put_line('Error while submitting program');
END;

FUNCTION submit_requests return NUMBER IS
ln_request_id NUMBER;
lv_req_number VARCHAR2(200);
lv_err_message VARCHAR2(200);
l_so_phase VARCHAR2(200);
l_req_phase VARCHAR2(200);
l_req_status VARCHAR2(200);
l_so_status VARCHAR2(200);
BEGIN

 submit_req_import_concurrent(l_req_phase,l_req_status,ln_request_id);

   IF UPPER(l_req_phase) = 'COMPLETED' AND UPPER(l_req_status) = 'NORMAL' THEN
      submit_create_order(l_so_phase,l_so_status);
      IF UPPER(l_so_phase) = 'COMPLETED' AND UPPER(l_so_status) = 'NORMAL' THEN
          BEGIN
          SELECT REQUISITION_HEADER_ID 
            INTO lv_req_number
            FROM po_requisition_headers_all
           WHERE request_id = ln_request_id
             AND type_lookup_code = 'INTERNAL';
          EXCEPTION WHEN OTHERS THEN
              lv_err_message := 'req did not create ';
          END;
          submit_order_import(lv_req_number);
     END IF;
   END IF;
return ln_request_id;
END;


PROCEDURE create_int_req( p_source_org IN VARCHAR2
                          ,p_destination_org IN VARCHAR2
                          ,p_item_number IN VARCHAR2
                          ,p_transfer_quantity IN VARCHAR2
						              ,p_source_subinventory IN VARCHAR2
                          ,p_dest_subinventory IN VARCHAR2
                          ,x_request_id OUT NUMBER
                          ,x_status OUT VARCHAR2
                          ,x_message OUT VARCHAR2) IS

ln_s_org_id       NUMBER;
ln_d_org_id       NUMBER;
ln_item_id        NUMBER;
lv_uom_code       VARCHAR2(200);
ln_operating_unit NUMBER;
ln_sn_count       NUMBER;
lv_req_number     VARCHAR2(200);
ln_request_id     NUMBER;
lv_err_message    VARCHAR2(4000);
e_error           EXCEPTION;

BEGIN
   --Fetch Source_organization Details
   BEGIN
      SELECT organization_id,operating_unit
        INTO ln_s_org_id,ln_operating_unit
        FROM org_organization_definitions
       WHERE organization_code = p_source_org;
   EXCEPTION WHEN OTHERS THEN
      lv_err_message := 'Incorrect value for source org '||p_source_org;
	  RAISE e_error;
   END;
   --Fetch destination organization Details
   BEGIN
      SELECT organization_id
        INTO ln_d_org_id
        FROM org_organization_definitions
       WHERE organization_code = p_destination_org;
   EXCEPTION WHEN OTHERS THEN
      lv_err_message := 'Incorrect value for destination org '||p_destination_org;
	  RAISE e_error;
   END;

   --Fetch item Details
   BEGIN
      SELECT inventory_item_id,primary_unit_of_measure
        INTO ln_item_id,lv_uom_code
        FROM mtl_system_items_b
       WHERE segment1 = p_item_number
	     AND organization_id = ln_s_org_id;
   EXCEPTION WHEN OTHERS THEN
      lv_err_message := 'Incorrect value for item number for source org '||p_item_number;
	  RAISE e_error;
   END;

   --validate item Details in destination
   BEGIN
      SELECT inventory_item_id
        INTO ln_item_id
        FROM mtl_system_items_b
       WHERE segment1 = p_item_number
	     AND organization_id = ln_d_org_id;
   EXCEPTION WHEN OTHERS THEN
      lv_err_message := 'Incorrect value for item number for destination org '||p_item_number;
	  RAISE e_error;
   END;
   
   --Validate shipping network
   SELECT count(0)
     INTO ln_sn_count
     FROM mtl_shipping_network_view a
    WHERE from_organization_code = p_source_org
      AND to_organization_code = p_destination_org
	  AND intransit_type = 2;
   IF ln_sn_count =0 THEN
      lv_err_message := 'Incorrect value for destination org '||p_destination_org;
	  RAISE e_error;
   END IF;	  

   SELECT to_char(sysdate,'DDMMRRRRHH24MISS')
     INTO gn_batch_id
	 FROM DUAL;

   INSERT INTO PO_REQUISITIONS_INTERFACE_ALL (INTERFACE_SOURCE_CODE,
                                           ORG_ID,
                                           DESTINATION_TYPE_CODE,
                                           AUTHORIZATION_STATUS,
                                           PREPARER_ID,
--                                           CHARGE_ACCOUNT_ID,
                                           SOURCE_TYPE_CODE,
                                           SOURCE_ORGANIZATION_ID,
                                           source_subinventory,
                                           UNIT_OF_MEASURE,
                                           LINE_TYPE_ID,
                                           QUANTITY,
                                           DESTINATION_ORGANIZATION_ID,
                                           destination_subinventory,
                                           DELIVER_TO_LOCATION_ID,
                                           DELIVER_TO_REQUESTOR_ID,
                                           ITEM_ID,
                                           BATCH_ID,
                                           NEED_BY_DATE)
     VALUES ('INT',                                  --Interface Source
             ln_operating_unit,                                             --Operating Unit
             'INVENTORY',                                   --Destination Type
             'APPROVED',                                            --Status
             24,                      --This comes from per_people_f.person_id
--             13401,           --Code Combination ID from M1 Inv Org Parameters
             'INVENTORY',                                        --Source Type
             ln_s_org_id,
             p_source_subinventory,
             lv_uom_code,                                                     --UOM
             1,                                           --Line Type of Goods
             p_transfer_quantity,                                                    --quantity
             ln_d_org_id,                                     --Represents M1 Seattle.
             p_dest_subinventory,
             ln_d_org_id,                                      --Represents M1-Seattle
             24,        
             ln_item_id,
			       gn_batch_id,
             SYSDATE + 2 
                        );
       commit;   
	   
ln_request_id := submit_requests();
   x_request_id := ln_request_id;
   x_status := 'S';
EXCEPTION 
WHEN e_error THEN
  x_status:='E';
  x_message:= lv_err_message;
WHEN OTHERS THEN
  x_message := 'Unknown error while loading interface table '||SQLERRM;
  x_status := 'E'  ;
END create_int_req;
                          
END XX_REQ_CREATE_PKG;