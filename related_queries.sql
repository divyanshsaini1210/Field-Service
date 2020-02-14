select * from fnd_conc_req_summary_v where request_id = 7734306;

select * from po_requisitions_interface_all where batch_id  like '13022020%';

delete from po_requisitions_interface_all where batch_id like '13022020%';

select * from po_requisition_headers_all where request_id = 7734342 order by creation_date desc;

select * from oe_headers_iface_all where orig_sys_document_ref IN ('538793',
'537791','537793');

SELECT responsibility_id,application_id,responsibility_name
--  INTO ln_resp_id,ln_app_id
from fnd_responsibility_tl where responsibility_name like'Order%Mana%';

select * from oe_order_headers_all where orig_sys_document_ref = '15915';

select * from oe_order_headers_all order by creation_date desc;--69334

      SELECT organization_id
--        INTO ln_d_org_id
        FROM org_organization_definitions
       WHERE organization_code = 'M2';

   SELECT count(0)
--     INTO ln_sn_count
     FROM mtl_shipping_network_view a
    WHERE from_organization_code = 'M1'
      AND to_organization_code = 'M2'
AND intransit_type = 2;

SELECT *--segment1 
--	  INTO lv_req_number
	  FROM po_requisition_headers_all
	 WHERE request_id = 7734306
     AND type_lookup_code = 'INTERNAL';
select order_number --into lv_order
from oe_order_headers_all
where orig_sys_document_ref = '15909';

select * from oe_order_sources where order_source_id = 10;