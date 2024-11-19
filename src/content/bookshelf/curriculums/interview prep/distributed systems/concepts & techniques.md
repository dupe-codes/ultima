## CAP Theorem

Consistency, availability, partition tolerance: choose two out of the three. But, network partitions are unavoidable. So it is more accurate to say CAP is _either_ be consistent or available when network partitioned.

## idempotency key

A strategy to resolve "double post" race conditions. `POST` requests to create resources are assigned some uniquely identifying key, which is used to constrain the creation of database records, either by application logic or a database constraint. For example,

```
POST /v1/reservations
{
    "hotel_id": 1234,
    ....
    "reservation_id": "fafb4-302a-344a"
}
```

the "reservation_id" field here can be used to ensure only one `POST` request to create a reservation is accepted.