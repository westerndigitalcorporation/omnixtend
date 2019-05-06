/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp       : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}
header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}
/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;
header vlan_tag_t vlan_tag[2];
header ipv4_t     ipv4;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

table eth_host {
    reads {
         ig_intr_md.ingress_port : exact;       
    }
    actions {
        send;
        discard;
    }
    default_action : send(128);
    size : 64;
}


control ingress {
    if (valid(ethernet)){
       apply(eth_host);
    }

}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}
