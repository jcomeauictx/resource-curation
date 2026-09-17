# resource-curation
various distributed means of archiving and curating digital resources

Claude recommended [dnslink](https://dnslink.dev/) for ipfs CIDs, and tor2web for .onion URLs.

We'll be using nsupdate with a bind9 server for the actual curation part, mapping human-readable names to IPFS CIDs:

First, get a key from the bind9 server: `tsig-keygen dnslink-key > /etc/bind/dnslink.key`, and copy it to the IPFS server.

Add to named.conf:
```
include "/etc/bind/dnslink.key";

zone "yourdomain.com" {
    type master;
    file "/etc/bind/zones/yourdomain.com.db";
    allow-update { key dnslink-key; };
};
```

Then from your IPFS machine, update the record:
```bash
nsupdate -k /path/to/dnslink.key << EOF
server your.bind9.server
zone yourdomain.com
update delete _dnslink.yourdomain.com TXT
update add _dnslink.yourdomain.com 60 TXT "/ipfs/<CID>"
send
EOF
```

## developer's notes
* Use human-readable IDs of less than 46 characters, the length of a CIDv0 hash.
* `rndc sync example.com` flushes `nsupdate`s to the zone file. can be done from a cron job.
