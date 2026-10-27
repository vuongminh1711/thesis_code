CIRCBUFLEN = 5
head = 0
tail = 0
buffer = [0] * CIRCBUFLEN

def insert(a):
    global head, tail, buffer
    if(is_full()):
        raise Exception("Buffer is full")
    buffer[head] = a
    head = (head + 1) % CIRCBUFLEN

def remove():
    global head, tail, buffer
    if(is_empty()):
        raise Exception("Buffer is empty")
    a = buffer[tail]
    tail = (tail + 1) % CIRCBUFLEN
    return a

def is_empty():
    global head, tail
    return head == tail

def is_full():
    global head, tail, CIRCBUFLEN
    return (head + 1) % CIRCBUFLEN == tail

def print_buffer():
    global head, tail, buffer
    if(is_empty()):
        print("Buffer is empty")
        return
    i = tail
    while i != head:
        print(buffer[i], end=" ")
        i = (i + 1) % CIRCBUFLEN
    print()


def main():
    insert(1)
    insert(2)
    insert(3)
    insert(4)
    print_buffer()
    print(remove())
    print(remove())
    print_buffer()
    insert(5)
    insert(6)
    print_buffer()

if __name__ == "__main__":
    main()