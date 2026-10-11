# Chain replication protocol

TLA+ project by Prof. Carla Ferreira for DARE 2026

## Assumptions

- The storage system is a single variable
- No failures occur
- Chain has size 2

## Behavior

- There are two types of requests:
  - Query requests (read): directed to the tail of the chain
  - Update requests (write): directed to the head of the chain
- The reply to every request is gemerated and sent by the tail
- State changes are forwarded along a reliable FIFO link to the next element of the chain
