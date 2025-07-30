#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/pkt_cls.h>

#ifndef IFINDEX
#define IFINDEX 2
#endif

SEC("tc/ingress")
int bpf_clone_redirect_example(struct __sk_buff *skb) {
    __u32 if_index = IFINDEX;

    int ret = bpf_clone_redirect(skb, if_index, 0); // redireciona para egress da interface destino

    if (ret) {
        bpf_printk("bpf_clone_redirect error: %d\n", ret);
    }

    return TC_ACT_OK;
}

char LICENSE[] SEC("license") = "Dual BSD/GPL";
