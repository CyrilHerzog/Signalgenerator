#---------------------------------------------------------------------------------------------------------------
#    File    : INTERFACE 
#    Version : 1.0
#    Author  : Herzog Cyril
#    Date    : 11.08.2024
#
#
#   pyserial red/write lsb first
#
#   info:  
#   read/write data from/to register bank
#   frame => [cmd_byte, data_bytes] => [rd/wr[7], mode[6], bank_addr[5:0], [data_byte[n], data_byte[n-1], ....]
#
#   singe mode: read/write data to bank_address => data_bytes must have the sum length of the register width of
#               the target bank => e.g bank_width = 14: 2 Bytes, bank_width = 5, 1 Byte, bank_width = 32, 4 Bytes
#
#   continuous mode: the address of the target bank is automatically incremented up to the maximum address. 
#                    Accordingly, a large number of data packets must be transmitted or expected to be received 
#---------------------------------------------------------------------------------------------------------------

import serial
import random
import time


################################################################################################################
# constant's
SINGLE_WRITE = 0b10000000
MULTI_WRITE  = 0b11000000
SINGLE_READ  = 0b00000000
MULTI_READ   = 0b01000000


def reverse_bits(byte):
    """lsb => msb"""
    return int('{:08b}'.format(byte)[::-1], 2)


def generate_random_numbers(num_bytes=2):
    return [random.randint(0, 255) for _ in range(num_bytes)]



# uart - parameter
ser = serial.Serial(
    'COM5',      # define your com - port 
    115200,
    timeout=5,
    parity=serial.PARITY_EVEN,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS
)


# all commands must be written in lsb first!
try:
    
    ############################################################################################################
    # echo - test write and read two random bytes
    random_bytes = generate_random_numbers(2)   
    print(f"send data (dec): {random_bytes}")
    ser.write(bytes([reverse_bits(SINGLE_WRITE) | 0b11000000])) 
    ser.write(bytes(random_bytes))  

    ser.write(bytes([reverse_bits(SINGLE_READ) | 0b11000000]))
    response = ser.read(2) 
    
    # check response
    dec_response = [byte for byte in response]
    print(f"receive data (dec): {dec_response}")
    if dec_response == random_bytes:
        print("test passed")
    else:
        print("test failed")

    # wait    
    time.sleep(1)


finally:
    ser.close()
