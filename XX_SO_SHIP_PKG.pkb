create or replace 
PACKAGE BODY XX_SO_SHIP_PKG AS


/******************** Auto Create Deliveries API Procedure ********************/
PROCEDURE AUTOCREATE_DELIVERIES_API(p_new_detail_id IN  NUMBER
                                      , o_delivery_id        OUT NUMBER
                                      , o_return_status      OUT VARCHAR2
                                      ,o_msg_data      OUT VARCHAR2)
IS
  l_api_version_number       NUMBER        := 1.0;
  l_return_status            VARCHAR2(200) := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  l_msg_count                NUMBER;
  l_msg_data                 VARCHAR2(3000);
  l_line_rows                WSH_UTIL_CORE.ID_TAB_TYPE;
  l_del_rows                 WSH_UTIL_CORE.ID_TAB_TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('autocreate_deliveries start '||p_new_detail_id);
  l_line_rows(1)  := p_new_detail_id;
  wsh_delivery_details_pub.autocreate_deliveries
  (
   p_api_version_number => l_api_version_number
  ,p_init_msg_list      => FND_API.G_FALSE
  ,p_commit             => FND_API.G_FALSE
  ,x_return_status      => l_return_status
  ,x_msg_count          => l_msg_count
  ,x_msg_data           => l_msg_data
  ,p_line_rows          => l_line_rows
  ,x_del_rows           => l_del_rows
  );
  o_delivery_id   := l_del_rows(1);
  o_return_status := l_return_status;
  o_msg_data       := NULL;
DBMS_OUTPUT.PUT_LINE('autocreate_deliveries end '||l_return_status);
  IF o_return_status = 'E' THEN
    FOR k IN l_msg_count-1 .. l_msg_count LOOP
      o_msg_data := fnd_msg_pub.get(p_msg_index => k, p_encoded => 'F')||' '||o_msg_data;
    END LOOP;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
  o_msg_data := 'Error while Creating Delivery For Line :'||SQLERRM;
  o_return_status := 'E';
END AUTOCREATE_DELIVERIES_API; 



/******************** Pick Release API Procedure ********************/
PROCEDURE CALL_PICK_RELEASE_API(p_delivery_id   IN  NUMBER
                              ,p_delivery_name IN  VARCHAR2
                              ,o_return_status OUT VARCHAR2
                              ,o_request_id    OUT VARCHAR2
                              ,o_msg_data      OUT VARCHAR2)
IS
  l_api_version_number NUMBER        := 1.0;
  l_return_status      VARCHAR2(200) := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2(3000);
  l_trip_id            NUMBER;
  l_trip_name          VARCHAR2(30);
  l_delivery_id        NUMBER;
  l_delivery_name      VARCHAR2(30);
  l_request_id         VARCHAR2(30);
BEGIN
  wsh_deliveries_pub.delivery_action
  (
   p_api_version_number => l_api_version_number
  ,p_init_msg_list      => FND_API.G_FALSE
  ,x_return_status      => l_return_status
  ,x_msg_count          => l_msg_count
  ,x_msg_data           => l_msg_data
  ,p_action_code        => 'PICK-RELEASE'
  ,p_delivery_id        => p_delivery_id
  ,p_delivery_name      => p_delivery_name
  ,x_trip_id            => l_trip_id
  ,x_trip_name          => l_trip_name
  );
  o_return_status := l_return_status;
  FOR k IN l_msg_count-1 .. l_msg_count LOOP
    o_msg_data := fnd_msg_pub.get(p_msg_index => k, p_encoded => 'F');
    IF k = l_msg_count-1 THEN
      o_request_id := SUBSTR(o_msg_data , INSTR(o_msg_data, 'request ID')+14, 7);
    END IF;
  END LOOP;
EXCEPTION
   WHEN OTHERS THEN
   o_msg_data := 'Error While Pick Release of Delivery :'||p_delivery_name||' and is :'||SQLERRM;
   o_return_status := 'E';
END CALL_PICK_RELEASE_API; -- End Of Pick Release API
/******************** Ship Confirm API Procedure ********************/
PROCEDURE CALL_SHIP_CONFIRM_API(p_delivery_id   IN  NUMBER
                              ,p_delivery_name IN  VARCHAR2
                              ,p_dispatch_date IN  DATE
                              ,o_return_status OUT VARCHAR2
                              ,o_msg_data      OUT VARCHAR2)
IS
  l_api_version_number     NUMBER        := 1.0;
  l_return_status          VARCHAR2(200) := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  l_msg_data               VARCHAR2(100);
  l_msg_count              NUMBER;
  l_trip_id                NUMBER;
  l_trip_name              VARCHAR2(30);
BEGIN
  wsh_deliveries_pub.delivery_action
  (
   p_api_version_number      => l_api_version_number
  ,p_init_msg_list           => FND_API.G_FALSE
  ,x_return_status           => l_return_status
  ,x_msg_count               => l_msg_count
  ,x_msg_data                => l_msg_data
  ,p_action_code             => 'CONFIRM'
  ,p_delivery_id             => p_delivery_id
  ,p_delivery_name           => p_delivery_name
  ,p_sc_action_flag          => 'S'
  ,p_sc_intransit_flag       => 'Y'
  ,p_sc_close_trip_flag      => 'Y'
  ,p_sc_stage_del_flag       => 'Y'
  ,p_sc_defer_interface_flag => 'N'
  ,p_sc_actual_dep_date      => p_dispatch_date
  ,x_trip_id                 => l_trip_id
  ,x_trip_name               => l_trip_name
  );
   o_return_status := l_return_status;
   o_msg_data      := NULL;
DBMS_OUTPUT.PUT_LINE('delivery_action                       :'||l_return_status);
  --IF o_return_status = 'E' THEN
    FOR k IN l_msg_count-1 .. l_msg_count LOOP
     -- IF k = l_msg_count THEN
        o_msg_data := fnd_msg_pub.get(p_msg_index => k, p_encoded => 'F')||' '||o_msg_data;
      --END IF;

    END LOOP;
DBMS_OUTPUT.PUT_LINE('o_msg_data     :'||o_msg_data);
  --END IF;
EXCEPTION
  WHEN OTHERS THEN
   o_msg_data := 'Error While Ship Confirm the Delivery :'||p_delivery_name||' and is :'||SQLERRM;
   o_return_status := 'E';
END CALL_SHIP_CONFIRM_API;

PROCEDURE MAIN 
(
p_organization_id IN NUMBER,
p_sales_order_num IN Number,
x_return_status OUT VARCHAR2,
x_ret_message OUT VARCHAR2
) IS

l_user_id            NUMBER;
l_resp_id            NUMBER;
l_resp_app_id        NUMBER;
l_error_flag         VARCHAR2(10) := 'N';
l_error_desc         VARCHAR2(4000);
l_error_code         NUMBER;
l_ship_from_org_id   NUMBER;
l_quantity_remaining NUMBER;
l_line_id            NUMBER;
l_ctn_org_id         NUMBER;
l_delivery_detail_id NUMBER;
l_sl_new_detail_id   NUMBER;
l_sl_return_status   VARCHAR2(30);
l_sl_msg_data        VARCHAR2(4000);
l_ret_status         VARCHAR2(100);
l_ac_return_status   VARCHAr2(100);
l_ac_msg_data        VARCHAR2(4000);
l_ac_delivery_id     NUMBER;
l_ud_return_status   VARCHAr2(100);
l_us_msg_data        VARCHAR2(4000);
l_us_return_status   VARCHAr2(100);
l_ud_msg_data        VARCHAR2(4000);
l_ud_delivery_id     NUMBER;
l_ud_delivery_name   NUMBER;
l_delivery_id        NUMBER;
l_pr_return_status   VARCHAR2(100);
l_pr_msg_data        VARCHAR2(4000);
l_pr_request_id1     NUMBER;
l_wr_phase           VARCHAR2(100);
l_wr_status          VARCHAR2(100);
l_wr_dev_phase       VARCHAR2(100);
l_wr_dev_status      VARCHAR2(100);
l_wr_message         VARCHAR2(4000);
l_delivery_name      VARCHAR2(100);
l_wr_output          BOOLEAN;
l_sc_return_status   VARCHAR2(100);
l_sc_request_id      NUMBER;
l_sc_msg_data        VARCHAR2(4000);
--l_sc_request_id      NUMBER;
l_sc_phase           VARCHAR2(100);
l_sc_status          VARCHAR2(100);
l_sc_dev_phase       VARCHAR2(100);
l_sc_dev_status      VARCHAR2(100);
l_sc_message         VARCHAR2(4000);

l_new_delivery_detail_id  NUMBER;

CURSOR c_so_data IS
SELECT ol.ordered_item item_code,ol.header_id ,oh.orig_sys_document_ref delivery_num,ordered_date
  FROM oe_order_headers_all oh,oe_order_lines_all ol 
 WHERE oh.header_id = ol.header_id
   AND order_number = p_sales_order_num;

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,
	' - Calling APPS_INITIALIZE - Parameters are'||chr(10)||
	'User id '||l_user_id||chr(10)||
	'Responsibility id '||l_resp_id||chr(10)||
	'Application Id ' ||l_resp_app_id
	);
  /******************** Initialize Global Variables ********************/
  l_user_id     := fnd_global.user_id;
  l_resp_id     := fnd_global.resp_id;
  l_resp_app_id := fnd_global.resp_appl_id;

SELECT user_id 
INTO l_user_id
FROM fnd_user 
WHERE user_name = 'SYSADMIN';

SELECT responsibility_id,application_id
  INTO l_resp_id,l_resp_app_id
from fnd_responsibility_tl where responsibility_name ='Order Management Super User, Vision Operations (USA)';

  FND_GLOBAL.APPS_INITIALIZE(user_id       => l_user_id ,
                             resp_id       => l_resp_id ,
                             resp_appl_id  => l_resp_app_id );
  DBMS_OUTPUT.PUT_LINE('Organization ID   :'||p_organization_id);
  
  --FND_CLIENT_INFO.SET_ORG_CONTEXT(102);
  MO_GLOBAL.SET_POLICY_CONTEXT('S','204');
	 
  FOR order_rec IN c_so_data LOOP
--	FND_FILE.PUT_LINE(FND_FILE.LOG,
--	' - Data being processed '||chr(10)||
--	'Header ID             :'||order_rec.header_id||chr(10)||
--	'Order Number          :'||order_rec.SalesOrder||chr(10)||
--	'Quantity              :'||order_rec.shipped_quantity||chr(10)||
--	'Item                  :'||order_rec.item_code
--	);
	
    /******************** Get Line Information   ********************/
    --
    -- Initialize Line Variables
    --
    l_line_id                 := NULL;
    l_quantity_remaining      := NULL;
    l_ship_from_org_id        := NULL;
    BEGIN
      SELECT l.line_id
            ,l.ship_from_org_id
            ,SUM(NVL(l.ordered_quantity, 0) - NVL(l.shipped_quantity, 0))  quantity_remaining
      INTO l_line_id
          ,l_ship_from_org_id
          ,l_quantity_remaining
      FROM oe_order_lines l
      WHERE 1 = 1
      AND l.header_id = order_rec.header_id
      AND l.ordered_item = order_rec.item_code
      AND l.flow_status_code NOT IN ('CLOSED', 'SHIPPED','CANCELLED')
      AND l.fulfilled_flag IS NULL
      AND l.invoice_interface_status_code IS NULL
      AND l.line_id = (SELECT MIN(l1.line_id)
                       FROM oe_order_lines l1
                       WHERE 1 = 1
                       AND l1.header_id = order_rec.header_id
                       AND l1.header_id = l.header_id
                       AND l1.ordered_item = order_rec.item_code
                       AND l1.flow_status_code NOT IN ('CLOSED', 'SHIPPED','CANCELLED')
                       AND l1.fulfilled_flag IS NULL
                       AND l1.invoice_interface_status_code IS NULL)
      GROUP BY l.line_id
              ,l.line_number
              ,l.shipment_number
              ,l.ship_from_org_id
      HAVING SUM(NVL(l.ordered_quantity, 0) - NVL(l.shipped_quantity, 0)) > 0;
		
		FND_FILE.PUT_LINE(FND_FILE.LOG,
	' - Data being processed '||chr(10)||
	'Line ID             :'||l_line_id||chr(10)||
	'Ship From Org ID    :'||l_ship_from_org_id||chr(10)||
	'Quan Remaining      :'||l_quantity_remaining
	);
		
    EXCEPTION
      WHEN OTHERS THEN
      l_error_flag  := 'Y';
      l_error_code  := SQLCODE;
      l_error_desc  := 'Error While Getting Line Information is : '||SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error Line ID     :'||SQLERRM);
    END;
    /******************** Check Ship From Org ID Count ********************/
    --
    -- Initialize Count of Organization ariables
    --
    l_ctn_org_id    := NULL;
    BEGIN
      SELECT COUNT(mp.organization_id)
      INTO l_ctn_org_id
      FROM mtl_parameters mp
      WHERE 1 = 1
     -- AND mp.organization_code = SUBSTR(order_rec.shipping_org,1,3)
      AND mp.organization_id = l_ship_from_org_id;
      DBMS_OUTPUT.PUT_LINE('Count Org ID             :'||l_ctn_org_id);
    EXCEPTION
      WHEN OTHERS THEN
      l_error_flag  := 'Y';
      l_error_code  := SQLCODE;
      l_error_desc := l_error_code|| 'Error While Getting Shipping Organization id is : '||SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error Count Org ID     :'||SQLERRM);
    END;
    /******************** Get Delivery Detail ID ********************/
    --
    -- Initialize Delivery Variables
    --
    l_delivery_detail_id      := NULL;
    BEGIN
      SELECT MAX(wdd.delivery_detail_id)
      INTO l_delivery_detail_id
      FROM wsh_delivery_details wdd
      WHERE 1 = 1
      AND wdd.source_header_id = order_rec.header_id
      AND wdd.source_line_id  = l_line_id
      AND (wdd.released_status = 'R'
        OR wdd.released_status = 'B'
        OR wdd.split_from_delivery_detail_id IS NULL )
      GROUP BY wdd.source_line_number;
		
      DBMS_OUTPUT.PUT_LINE('Delivery Detail ID         :'||l_delivery_detail_id);
    EXCEPTION
      WHEN OTHERS THEN
      l_error_flag  := 'Y';
      l_error_code  := SQLCODE;
      l_error_desc  := 'Error While Getting Delivery Challan Line Information is : '||SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error Delivery / Source Line Number         :'||SQLERRM);
    END;


    /******************** Processing Records ********************/
    IF (l_error_flag = 'N')
        AND (l_ctn_org_id = 1) THEN
      /******************** Call Auto Create Deliveries Procedure ********************/
      --
      -- Initialize Autocreate Deliveries Variables Variables
      --
DBMS_OUTPUT.PUT_LINE('Auto Create Deliveries start     :'||l_ac_return_status);
      l_ac_return_status    := NULL;
      l_ac_msg_data         := NULL;
      l_ac_delivery_id      := NULL;
        AUTOCREATE_DELIVERIES_API(l_delivery_detail_id
                                     ,l_ac_delivery_id
                                     ,l_ac_return_status
                                     ,l_ac_msg_data);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Auto Create Deliveries Completed     :'||l_ac_return_status);
      /******************** Call Pick Release Procedure ********************/
      --
      -- Initialize Pick Release Variables
      --
      l_pr_return_status := NULL;
      l_pr_request_id1   := NULL;
      l_pr_msg_data      := NULL;
      IF l_ac_return_status = 'S' THEN
        l_error_code        := NULL;
        l_error_desc        := NULL;
        l_delivery_id       := l_ac_delivery_id;
        l_delivery_name     := NULL;
        CALL_PICK_RELEASE_API (l_delivery_id
                             ,l_delivery_name
                             ,l_pr_return_status
                             ,l_pr_request_id1
                             ,l_pr_msg_data);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Pick Release Completed                        :'||l_pr_return_status);
        --
        -- Wait For Request Completion after Pick Release
        --
        BEGIN
          l_wr_output := fnd_concurrent.wait_for_request(
                                                         request_id => l_pr_request_id1
                                                        ,INTERVAL   => 90
                                                        ,max_wait   => 90
                                                        ,phase      => l_wr_phase
                                                        ,status     => l_wr_status
                                                        ,dev_phase  => l_wr_dev_phase
                                                        ,dev_status => l_wr_dev_status
                                                        ,message    => l_wr_message
                                                        );
        END;-- Wait For Request
        DBMS_OUTPUT.PUT_LINE('Pick Release Wait Req Status            :'||l_wr_phase||' '||l_wr_status);
      END IF;
      /******************** Call Ship Confirm Procedure ********************/
      --
      -- Initialize Ship Confirm Variables
      --
      l_sc_return_status := NULL;
      l_sc_msg_data      := NULL;
      IF UPPER(l_wr_phase) = 'COMPLETED'
         AND UPPER(l_wr_status) = 'NORMAL'
         AND l_pr_return_status = 'S' THEN
        l_ret_status        := 'Success - Pick Release';
        l_error_code        := NULL;
        l_error_desc        := NULL;
        l_delivery_id       := l_ac_delivery_id;
        l_delivery_name     := order_rec.delivery_num;
        CALL_SHIP_CONFIRM_API(l_delivery_id
                            ,l_delivery_name
                            ,order_rec.ordered_date
                            ,l_sc_return_status
                            ,l_sc_msg_data);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Ship Confirm Completed                        :'||l_sc_return_status);
        DBMS_OUTPUT.PUT_LINE('Ship Confirm Completed                        :'||l_sc_return_status);
      END IF;
      /******************** Get Request ID and Wait Till Compltetion Of Request ********************/
      --
      -- Initialize Request id Variables
      --
      l_sc_request_id  := NULL;
      IF UPPER(l_wr_phase) = 'COMPLETED'
         AND UPPER(l_wr_status) = 'NORMAL'
         AND (l_sc_return_status = 'S' OR l_sc_return_status = 'W') THEN
        l_ret_status    := 'Success - Ship Confirm';
        l_error_code  := NULL;
        l_error_desc  := NULL;
        --
        -- Get Reuest ID For Interface Trip Stop
        --
        BEGIN
          SELECT MAX(a.request_id)
          INTO l_sc_request_id
          FROM fnd_conc_req_summary_v a
          WHERE 1 = 1
          AND UPPER(a.user_concurrent_program_name) = 'INTERFACE TRIP STOP'
          AND a.requested_by = l_user_id
          AND a.responsibility_application_id = l_resp_app_id
          AND a.responsibility_id = l_resp_id
          GROUP BY a.user_concurrent_program_name;
          DBMS_OUTPUT.PUT_LINE('INTERFACE TRIP STOP Get Request ID                        :'||l_sc_request_id);
        EXCEPTION
          WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR INTERFACE TRIP STOP Get Request ID     :'||SQLERRM);
          --NULL;
        END;
        l_sc_phase        := NULL;
        l_sc_status       := NULL;
        l_sc_dev_phase    := NULL;
        l_sc_dev_status   := NULL;
        l_sc_message      := NULL;
        BEGIN
          l_wr_output := fnd_concurrent.wait_for_request(
                                                         request_id => l_sc_request_id
                                                        ,INTERVAL   => 60
                                                        ,max_wait   => 0
                                                        ,phase      => l_sc_phase
                                                        ,status     => l_sc_status
                                                        ,dev_phase  => l_sc_dev_phase
                                                        ,dev_status => l_sc_dev_status
                                                        ,message    => l_sc_message
                                                        );
        END;
      END IF;
      /******************** Set Error / Status when Auto Create Delivery Status = E ********************/
      IF l_ac_return_status = 'E' THEN
        l_ret_status    := 'Error - Autocreate Deliveries';
        l_error_desc := l_error_code|| l_ac_msg_data;
        DBMS_OUTPUT.PUT_LINE('Error Autocreate Deliveries                     :'||l_ret_status||' '||l_error_desc);
      END IF;
      /******************** Set Error / Status when Pick Release Status = E ********************/
      IF l_pr_return_status = 'E' THEN
        l_ret_status    := 'Error - Pick Release';
        l_error_desc  := l_pr_msg_data;
        DBMS_OUTPUT.PUT_LINE('Error Pick Release                        :'||l_ret_status||' '||l_error_desc);
      END IF;
      /******************** Set Error / Status when Ship Confirm Status = E ********************/
      IF l_sc_return_status = 'E' THEN
        l_ret_status    := 'Error - Ship Confirm';
        l_error_desc  := l_sc_msg_data;
        DBMS_OUTPUT.PUT_LINE('Error Ship Confirm                        :'||l_ret_status||' '||l_error_desc);
      END IF;
    ELSE
      l_ret_status := 'Error';
    END IF;
    COMMIT; --End of All Records
	x_return_status :=l_ret_status;
	x_ret_message:= l_error_desc;
   END LOOP;
EXCEPTION WHEN OTHERS THEN
     x_return_status := 'E';
     x_ret_message := 'Unexpected error in main sales order package '||SQLERRM; 
END;

END XX_SO_SHIP_PKG;