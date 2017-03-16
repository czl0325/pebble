//
//  ORSSerialPort.h
//  ORSSerialPort
//
//  Created by Andrew R. Madsen on 08/6/11.
//	Copyright (c) 2011-2014 Andrew R. Madsen (andrew@openreelsoftware.com)
//	
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//	
//	The above copyright notice and this permission notice shall be included
//	in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <IOKit/IOTypes.h>
#import <termios.h>

//#define LOG_SERIAL_PORT_ERRORS 

enum {
	ORSSerialPortParityNone = 0,
	ORSSerialPortParityOdd,
	ORSSerialPortParityEven
}; typedef NSUInteger ORSSerialPortParity;

@protocol ORSSerialPortDelegate;

/**
 *  The ORSSerialPort class represents a serial port, and includes methods to
 *  configure, open and close a port, and send and receive data to and from
 *  a port.
 *
 *  There is a 1:1 correspondence between port devices on the
 *  system and instances of `ORSSerialPort`. That means that repeated requests
 *  for a port object for a given device or device path will return the same 
 *  instance of `ORSSerialPort`.
 *
 *  Opening a Port and Setting It Up
 *  --------------------------------
 *
 *  You can get an `ORSSerialPort` instance either of two ways. The easiest
 *  is to use `ORSSerialPortManager`'s `availablePorts` array. The other way
 *  is to get a new `ORSSerialPort` instance using the serial port's BSD device path:
 *
 *  	ORSSerialPort *port = [ORSSerialPort serialPortWithPath:@"/dev/cu.KeySerial1"];
 *
 *  Note that you must give `+serialPortWithPath:` the full path to the
 *  device, as shown in the example above.
 *
 *
 *  After you've got a port instance, you can open it with the `-open`
 *  method. When you're done using the port, close it using the `-close`
 *  method.
 *
 *  Port settings such as baud rate, number of stop bits, parity, and flow
 *  control settings can be set using the various properties `ORSSerialPort`
 *  provides. Note that all of these properties are Key Value Observing
 *  (KVO) compliant. This KVO compliance also applies to read-only
 *  properties for reading the state of the CTS, DSR and DCD pins. Among
 *  other things, this means it's easy to be notified when the state of one
 *  of these pins changes, without having to continually poll them, as well
 *  as making them easy to connect to a UI with Cocoa bindings.
 *
 *  Sending Data
 *  ------------
 *
 *  Send data by passing an `NSData` object to the `-sendData:` method:
 *
 *  	NSData *dataToSend = [self.sendTextField.stringValue dataUsingEncoding:NSUTF8StringEncoding];
 *  	[self.serialPort sendData:dataToSend];
 *
 *  Receiving Data
 *  --------------
 *
 *  To receive data, you must implement the `ORSSerialPortDelegate`
 *  protocol's `-serialPort:didReceiveData:` method, and set the
 *  `ORSSerialPort` instance's delegate property. As noted in the documentation
 *  for ORSSerialPortDelegate, this method is always called on the main queue.
 *  An example implementation is included below:
 *
 *  	- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
 *  	{
 *  		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
 *  		[self.receivedDataTextView.textStorage.mutableString appendString:string];
 *  		[self.receivedDataTextView setNeedsDisplay:YES];
 *  	}
 */

@interface ORSSerialPort : NSObject

/** ---------------------------------------------------------------------------------------
 * @name Getting a Serial Port
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns an `ORSSerialPort` instance representing the serial port at `devicePath`.
 *
 *  `devicePath` must be the full, callout (cu.) or tty (tty.) path to an available
 *  serial port device on the system.
 *
 *  @param devicePath The full path (e.g. /dev/cu.usbserial) to the device.
 *
 *  @return An initalized `ORSSerialPort` instance, or nil if there was an error.
 * 
 *  @see -[ORSSerialPortManager availablePorts]
 *  @see -initWithPath:
 */
+ (ORSSerialPort *)serialPortWithPath:(NSString *)devicePath;

/**
 *  Returns an `ORSSerialPort` instance for the serial port represented by `device`.
 *
 *  Generally, `+serialPortWithPath:` is the method to use to get port instances
 *  programatically. This method may be useful if you're doing your own
 *  device discovery with IOKit functions, or otherwise have an IOKit port object
 *  you want to "turn into" an ORSSerialPort. Most people will not use this method
 *  directly.
 *
 *  @param device An IOKit port object representing the serial port device.
 *
 *  @return An initalized `ORSSerialPort` instance, or nil if there was an error.
 *
 *  @see -[ORSSerialPortManager availablePorts]
 *  @see +serialPortWithPath:
 */
+ (ORSSerialPort *)serialPortWithDevice:(io_object_t)device;

/**
 *  Returns an `ORSSerialPort` instance representing the serial port at `devicePath`.
 *
 *  `devicePath` must be the full, callout (cu.) or tty (tty.) path to an available
 *  serial port device on the system.
 *
 *  @param devicePath The full path (e.g. /dev/cu.usbserial) to the device.
 *
 *  @return An initalized `ORSSerialPort` instance, or nil if there was an error.
 *
 *  @see -[ORSSerialPortManager availablePorts]
 *  @see +serialPortWithPath:
 */
- (id)initWithPath:(NSString *)devicePath;

/**
 *  Returns an `ORSSerialPort` instance for the serial port represented by `device`.
 *
 *  Generally, `-initWithPath:` is the method to use to get port instances
 *  programatically. This method may be useful if you're doing your own
 *  device discovery with IOKit functions, or otherwise have an IOKit port object
 *  you want to "turn into" an ORSSerialPort. Most people will not use this method
 *  directly.
 *
 *  @param device An IOKit port object representing the serial port device.
 *
 *  @return An initalized `ORSSerialPort` instance, or nil if there was an error.
 *
 *  @see -[ORSSerialPortManager availablePorts]
 *  @see -initWithPath:
 */
- (id)initWithDevice:(io_object_t)device;

/** ---------------------------------------------------------------------------------------
 * @name Opening and Closing
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Opens the port represented by the receiver.
 *
 *  If this method succeeds, the ORSSerialPortDelegate method `-serialPortWasOpened:` will
 *  be called.
 *
 *  If opening the port fails, the ORSSerialPortDelegate method `-serialPort:didEncounterError:` will
 *  be called.
 */
- (BOOL)open;

/**
 *  Closes the port represented by the receiver.
 *
 *  If the port is closed successfully, the ORSSerialPortDelegate method `-serialPortWasClosed:` will
 *  be called before this method returns.
 *
 *  @return YES if closing the port was closed successfully, NO if closing the port failed.
 */
- (BOOL)close;

- (void)cleanup DEPRECATED_ATTRIBUTE; // Should never have been called in client code, anyway.

/**
 *  Closes the port and cleans up.
 *
 *  This method should never be called directly. Call `-close` to close a port instead.
 */
- (void)cleanupAfterSystemRemoval;

/** ---------------------------------------------------------------------------------------
 * @name Sending Data
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Sends data out through the serial port represented by the receiver.
 *
 *  This method attempts to send all data synchronously. If the serial port
 *  is unable to accept all the passed in data in a single write operation,
 *  The remaining data is buffered and sent later asynchronously.
 *
 *  If an error occurs, the ORSSerialPortDelegate method `-serialPort:didEncounterError:` will
 *  be called. The exception to this is if sending data fails because the port
 *  is closed. In that case, this method returns NO, but `-serialPort:didEncounterError:`
 *  is *not* called. You can ensure that the port is open by calling `-isOpen` before 
 *  calling this method.
 *
 *  @param data An `NSData` object containing the data to be sent.
 *
 *  @return YES if sending data failed, NO if an error occurred.
 */
- (BOOL)sendData:(NSData *)data;

- (NSData*)initiativeRecvData;

@property (assign, nonatomic) BOOL isReadBackground;

/** ---------------------------------------------------------------------------------------
 * @name Delegate
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  The delegate for the serial port object. Must implement the `ORSSerialPortDelegate` protocol.
 *
 */
@property (nonatomic, unsafe_unretained) id<ORSSerialPortDelegate> delegate;

/** ---------------------------------------------------------------------------------------
 * @name Port Object Properties
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  A Boolean value that indicates whether the port is open. (read-only)
 */
@property (readonly, getter = isOpen) BOOL open;

/**
 *  An string representation of the device path for the serial port represented by the receiver. (read-only)
 */
@property (copy, readonly) NSString *path;

/**
 *  The IOKit port object for the serial port device represented by the receiver. (read-only)
 */
@property (readonly) io_object_t IOKitDevice;

/**
 *  The name of the serial port. 
 *  
 *  Can be presented to the user, e.g. in a serial port selection pop up menu.
 */
@property (copy, readonly) NSString *name;

/** ---------------------------------------------------------------------------------------
 * @name Configuring the Serial Port
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  The baud rate for the port.
 *
 *  This value should be one of the values defined in termios.h:
 *
 *	- 0
 *	- 50
 *	- 75
 *	- 110
 *	- 134
 *	- 150
 *	- 200
 *	- 300
 *	- 600
 *	- 1200
 *	- 1800
 *	- 2400
 *	- 4800
 *	- 9600
 *	- 19200
 *	- 38400
 *	- 7200
 *	- 14400
 *	- 28800
 *	- 57600
 *	- 76800
 *	- 115200
 *	- 230400
 *	- 19200
 *	- 38400
 */
@property (nonatomic, copy) NSNumber *baudRate;

/**
 *  The number of stop bits. Values other than 1 or 2 are invalid.
 */
@property (nonatomic) NSUInteger numberOfStopBits;

/**
 *
 */
@property (nonatomic) BOOL shouldEchoReceivedData;

/**
 *  The parity setting for the port. Possible values are:
 *  
 *  - ORSSerialPortParityNone
 *  - ORSSerialPortParityOdd
 *  - ORSSerialPortParityEven
 */
@property (nonatomic) ORSSerialPortParity parity;

/**
 *  A Boolean value indicating whether the serial port uses RTS/CTS Flow Control.
 */
@property (nonatomic) BOOL usesRTSCTSFlowControl;

/**
 *  A Boolean value indicating whether the serial port uses DTR/DSR Flow Control.
 */
@property (nonatomic) BOOL usesDTRDSRFlowControl;

/**
 *  A Boolean value indicating whether the serial port uses DCD Flow Control.
 */
@property (nonatomic) BOOL usesDCDOutputFlowControl;

/** ---------------------------------------------------------------------------------------
 * @name Other Port Pins
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  The state of the serial port's RTS pin.
 *
 *  - YES means 1 or high state.
 *  - NO means 0 or low state.
 *
 *  This property is observable using Key Value Observing.
 */
@property (nonatomic) BOOL RTS;

/**
 *  The state of the serial port's DTR pin.
 *
 *  - YES means 1 or high state.
 *  - NO means 0 or low state.
 *
 *  This property is observable using Key Value Observing.
 */
@property (nonatomic) BOOL DTR;

/**
 *  The state of the serial port's CTS pin.
 *
 *  - YES means 1 or high state.
 *  - NO means 0 or low state.
 *
 *  This property is observable using Key Value Observing.
 */
@property (nonatomic, readonly) BOOL CTS;

/**
 *  The state of the serial port's DSR pin. (read-only)
 *
 *  - YES means 1 or high state.
 *  - NO means 0 or low state.
 *
 *  This property is observable using Key Value Observing.
 */
@property (nonatomic, readonly) BOOL DSR;

/**
 *  The state of the serial port's DCD pin. (read-only)
 *
 *  - YES means 1 or high state.
 *  - NO means 0 or low state.
 *
 *  This property is observable using Key Value Observing.
 */
@property (nonatomic, readonly) BOOL DCD;

@end

/**
 *  The ORSSerialPortDelegate protocol defines methods to be implemented
 *  by the delegate of an `ORSSerialPort` object.
 *
 *  *Note*: All `ORSSerialPortDelegate` methods are always called on the main queue.
 *  If you need to handle them on a background queue, you must dispatch your handling
 *  to a background queue in your implementation of the delegate method.
 */

@protocol ORSSerialPortDelegate

@required

/**
 *  Called when new data is received by the serial port from an external source.
 *
 *  @param serialPort The `ORSSerialPort` instance representing the port that received `data`.
 *  @param data       An `NSData` instance containing the data received.
 */
- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data;

/**
 *  Called when a serial port is removed from the system, e.g. the user unplugs
 *  the USB to serial adapter for the port.
 *
 *	In this method, you should discard any strong references you have maintained for the
 *  passed in `serialPort` object. The behavior of `ORSSerialPort` instances whose underlying
 *  serial port has been removed from the system is undefined.
 *
 *  @param serialPort The `ORSSerialPort` instance representing the port that was removed.
 */
- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;

@optional

/**
 *  Called when an error occurs during an operation involving a serial port.
 *
 *	This method is always used to report errors. No `ORSSerialPort` methods
 *  take a passed in `NSError **` reference because errors may occur asynchonously,
 *  after a method has returned.
 *
 *	Currently, errors reported using this method are always in the `NSPOSIXErrorDomain`,
 *  and a list of error codes can be found in the system header errno.h.
 *
 *  The error object's userInfo dictionary contains the following keys:
 *
 *	- NSLocalizedDescriptionKey - An error message string.
 *	- NSFilePathErrorKey - The device path to the serial port. Same as `[serialPort path]`.
 *
 *  @param serialPort The `ORSSerialPort` instance for the port
 *  @param error      An `NSError` object containing information about the error.
 */
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error;

/**
 *  Called when a serial port is successfully opened.
 *
 *  @param serialPort The `ORSSerialPort` instance representing the port that was opened.
 */
- (void)serialPortWasOpened:(ORSSerialPort *)serialPort;

/**
 *  Called when a serial port was closed (e.g. because `-close`) was called.
 *
 *  @param serialPort The `ORSSerialPort` instance representing the port that was closed.
 */
- (void)serialPortWasClosed:(ORSSerialPort *)serialPort;

@end