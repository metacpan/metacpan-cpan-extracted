#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libusb.h>

#include "const-c.inc"

typedef libusb_context *USB__LibUSB__XS;
typedef libusb_device *USB__LibUSB__XS__Device;
typedef libusb_device_handle *USB__LibUSB__XS__Device__Handle;

static void
do_not_warn_unused(void *x __attribute__((__unused__)))
{
}

static SV *
ss_ep_comp_to_HV(pTHX_ struct libusb_ss_endpoint_companion_descriptor *ep_comp)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(ep_comp->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(ep_comp->bDescriptorType));
    hv_stores(rv, "bMaxBurst", newSVuv(ep_comp->bMaxBurst));
    hv_stores(rv, "bmAttributes", newSVuv(ep_comp->bmAttributes));
    hv_stores(rv, "wBytesPerInterval", newSVuv(ep_comp->wBytesPerInterval));
    return newRV_noinc((SV *) rv);
}

static SV *
endpoint_descriptor_to_HV(pTHX_ libusb_context *ctx, const struct libusb_endpoint_descriptor *endpoint)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(endpoint->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(endpoint->bDescriptorType));
    hv_stores(rv, "bEndpointAddress", newSVuv(endpoint->bEndpointAddress));
    hv_stores(rv, "bmAttributes", newSVuv(endpoint->bmAttributes));
    hv_stores(rv, "wMaxPacketSize", newSVuv(endpoint->wMaxPacketSize));
    hv_stores(rv, "bInterval", newSVuv(endpoint->bInterval));
    hv_stores(rv, "bRefresh", newSVuv(endpoint->bRefresh));
    hv_stores(rv, "bSynchAddress", newSVuv(endpoint->bSynchAddress));
    hv_stores(rv, "extra", newSVpvn((const char *)endpoint->extra, endpoint->extra_length));
  
    struct libusb_ss_endpoint_companion_descriptor *ep_comp;
    int value = libusb_get_ss_endpoint_companion_descriptor(ctx, endpoint, &ep_comp);
    if (value == 0) {
        hv_stores(rv, "ss_endpoint_companion", ss_ep_comp_to_HV(aTHX_ ep_comp));
        libusb_free_ss_endpoint_companion_descriptor(ep_comp);
    }
    else if (value != LIBUSB_ERROR_NOT_FOUND)
        croak("Error in libusb_get_ss_endpoint_companion_descriptor");
    return newRV_noinc((SV *) rv);
}

static SV *
endpoint_array_to_AV(pTHX_ libusb_context *ctx, const struct libusb_endpoint_descriptor *endpoint, int num_endpoints)
{
    AV *rv = newAV();
    for (int i = 0; i < num_endpoints; ++i)
        av_push(rv, endpoint_descriptor_to_HV(aTHX_ ctx, &endpoint[i]));
    return newRV_noinc((SV *) rv);
}


static SV *
interface_descriptor_to_HV(pTHX_ libusb_context *ctx, const struct libusb_interface_descriptor *interface)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(interface->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(interface->bDescriptorType));
    hv_stores(rv, "bInterfaceNumber", newSVuv(interface->bInterfaceNumber));
    hv_stores(rv, "bAlternateSetting", newSVuv(interface->bAlternateSetting));
    hv_stores(rv, "bNumEndpoints", newSVuv(interface->bNumEndpoints));
    hv_stores(rv, "bInterfaceClass", newSVuv(interface->bInterfaceClass));
    hv_stores(rv, "bInterfaceSubClass", newSVuv(interface->bInterfaceSubClass));
    hv_stores(rv, "bInterfaceProtocol", newSVuv(interface->bInterfaceProtocol));
    hv_stores(rv, "iInterface", newSVuv(interface->iInterface));
    hv_stores(rv, "endpoint", endpoint_array_to_AV(aTHX_ ctx, interface->endpoint, interface->bNumEndpoints));
    hv_stores(rv, "extra", newSVpvn((const char *) interface->extra, interface->extra_length));
    return newRV_noinc((SV *) rv);
}

static SV *
altsetting_array_to_AV(pTHX_ libusb_context *ctx, const struct libusb_interface *interface)
{
    AV *rv = newAV();
    for (int i = 0; i < interface->num_altsetting; ++i)
        av_push(rv, interface_descriptor_to_HV(aTHX_ ctx, &interface->altsetting[i]));
    return newRV_noinc((SV *) rv);  
}

static SV *
interface_array_to_AV(pTHX_ libusb_context *ctx, const struct libusb_interface *interface, int num_interfaces)
{
    AV *rv = newAV();
    for (int i = 0; i < num_interfaces; ++i)
        av_push(rv, altsetting_array_to_AV(aTHX_ ctx, &interface[i]));
    return newRV_noinc((SV *) rv);
}

static SV *
config_descriptor_to_RV(pTHX_ libusb_context *ctx, struct libusb_config_descriptor *config)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(config->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(config->bDescriptorType));
    hv_stores(rv, "wTotalLength", newSVuv(config->wTotalLength));
    hv_stores(rv, "bNumInterfaces", newSVuv(config->bNumInterfaces));
    hv_stores(rv, "bConfigurationValue", newSVuv(config->bConfigurationValue));
    hv_stores(rv, "iConfiguration", newSVuv(config->iConfiguration));
    hv_stores(rv, "bmAttributes", newSVuv(config->bmAttributes));
    hv_stores(rv, "MaxPower", newSVuv(config->MaxPower));
    hv_stores(rv, "interface", interface_array_to_AV(aTHX_ ctx, config->interface, config->bNumInterfaces));
    hv_stores(rv, "extra", newSVpvn((const char *) config->extra, config->extra_length));
    return newRV_noinc((SV *) rv);
}

static SV *
usb_2_0_extension_to_HV(pTHX_ libusb_context *ctx, struct libusb_bos_dev_capability_descriptor *dev_cap)
{
    struct libusb_usb_2_0_extension_descriptor *usb_2_0_extension;
    int value =  libusb_get_usb_2_0_extension_descriptor(ctx, dev_cap, &usb_2_0_extension);
    if (value != 0)
        croak("error in libusb_get_usb_2_0_extension_descriptor");
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(usb_2_0_extension->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(usb_2_0_extension->bDescriptorType));
    hv_stores(rv, "bDevCapabilityType", newSVuv(usb_2_0_extension->bDevCapabilityType));
    hv_stores(rv, "bmAttributes", newSVuv(usb_2_0_extension->bmAttributes));
    libusb_free_usb_2_0_extension_descriptor(usb_2_0_extension);
    return newRV_noinc((SV *) rv);
}

static SV *
ss_usb_device_capability_to_HV(pTHX_ libusb_context *ctx, struct libusb_bos_dev_capability_descriptor *dev_cap)
{
    struct libusb_ss_usb_device_capability_descriptor *ss_usb_device_capability;
    int value =  libusb_get_ss_usb_device_capability_descriptor(ctx, dev_cap, &ss_usb_device_capability);
    if (value != 0)
        croak("error in libusb_get_ss_usb_device_capability_descriptor");
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(ss_usb_device_capability->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(ss_usb_device_capability->bDescriptorType));
    hv_stores(rv, "bDevCapabilityType", newSVuv(ss_usb_device_capability->bDevCapabilityType));
    hv_stores(rv, "bmAttributes", newSVuv(ss_usb_device_capability->bmAttributes));
    hv_stores(rv, "wSpeedSupported", newSVuv(ss_usb_device_capability->wSpeedSupported));
    hv_stores(rv, "bFunctionalitySupport", newSVuv(ss_usb_device_capability->bFunctionalitySupport));
    hv_stores(rv, "bU1DevExitLat", newSVuv(ss_usb_device_capability->bU1DevExitLat));
    hv_stores(rv, "bU2DevExitLat", newSVuv(ss_usb_device_capability->bU2DevExitLat));
    libusb_free_ss_usb_device_capability_descriptor(ss_usb_device_capability);
    return newRV_noinc((SV *) rv);
}

static SV *
container_id_to_HV(pTHX_ libusb_context *ctx, struct libusb_bos_dev_capability_descriptor *dev_cap)
{
    struct libusb_container_id_descriptor *container_id;
    int value =  libusb_get_container_id_descriptor(ctx, dev_cap, &container_id);
    if (value != 0)
        croak("error in libusb_get_container_id_descriptor");
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(container_id->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(container_id->bDescriptorType));
    hv_stores(rv, "bDevCapabilityType", newSVuv(container_id->bDevCapabilityType));
    hv_stores(rv, "bReserved", newSVuv(container_id->bReserved));
    hv_stores(rv, "ContainerID", newSVpvn((const char *) container_id->ContainerID, 16));
    libusb_free_container_id_descriptor(container_id);
    return newRV_noinc((SV *) rv);
}

static SV *
bos_dev_capability_descriptor_to_HV(pTHX_ libusb_context *ctx, struct libusb_bos_dev_capability_descriptor *dev_cap)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(dev_cap->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(dev_cap->bDescriptorType));
    unsigned capability_type = dev_cap->bDevCapabilityType;
    hv_stores(rv, "bDevCapabilityType", newSVuv(capability_type));
    hv_stores(rv, "dev_capability_data", newSVpvn((const char *) dev_cap->dev_capability_data, dev_cap->bLength - 3));
    switch (capability_type) {
        case LIBUSB_BT_USB_2_0_EXTENSION:
            hv_stores(rv, "usb_2_0_extension", usb_2_0_extension_to_HV(aTHX_ ctx, dev_cap));
            break;
        case LIBUSB_BT_SS_USB_DEVICE_CAPABILITY:
            hv_stores(rv, "ss_usb_device_capability", ss_usb_device_capability_to_HV(aTHX_ ctx, dev_cap));
            break;
        case LIBUSB_BT_CONTAINER_ID:
            hv_stores(rv, "container_id", container_id_to_HV(aTHX_ ctx, dev_cap));
            break;
    }
    
    return newRV_noinc((SV *) rv);
}

static SV *
dev_capability_array_to_AV(pTHX_ libusb_context *ctx, struct libusb_bos_dev_capability_descriptor **dev_capability, uint8_t bNumDeviceCaps)
{
    AV *rv = newAV();
    for (int i = 0; i < bNumDeviceCaps; ++i)
        av_push(rv, bos_dev_capability_descriptor_to_HV(aTHX_ ctx, dev_capability[i]));
    return newRV_noinc((SV *) rv);
}

static SV *
bos_descriptor_to_RV(pTHX_ libusb_context *ctx, struct libusb_bos_descriptor *bos)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(bos->bLength));
    hv_stores(rv, "bDescriptorType", newSVuv(bos->bDescriptorType));
    hv_stores(rv, "wTotalLength", newSVuv(bos->wTotalLength));
    hv_stores(rv, "bNumDeviceCaps", newSVuv(bos->bNumDeviceCaps));
    hv_stores(rv, "dev_capability", dev_capability_array_to_AV(aTHX_ ctx, bos->dev_capability, bos->bNumDeviceCaps));
    return newRV_noinc((SV *) rv);
}


static SV *
device_descriptor_to_RV(pTHX_ struct libusb_device_descriptor *desc)
{
    HV *rv = newHV();
    hv_stores(rv, "bLength", newSVuv(desc->bLength));    
    hv_stores(rv, "bDescriptorType", newSVuv(desc->bDescriptorType));
    hv_stores(rv, "bcdUSB", newSVuv(desc->bcdUSB));
    hv_stores(rv, "bDeviceClass", newSVuv(desc->bDeviceClass));
    hv_stores(rv, "bDeviceSubClass", newSVuv(desc->bDeviceSubClass));
    hv_stores(rv, "bDeviceProtocol", newSVuv(desc->bDeviceProtocol));
    hv_stores(rv, "bMaxPacketSize0", newSVuv(desc->bMaxPacketSize0));
    hv_stores(rv, "idVendor", newSVuv(desc->idVendor));
    hv_stores(rv, "idProduct", newSVuv(desc->idProduct));
    hv_stores(rv, "bcdDevice", newSVuv(desc->bcdDevice));
    hv_stores(rv, "iManufacturer", newSVuv(desc->iManufacturer));
    hv_stores(rv, "iProduct", newSVuv(desc->iProduct));
    hv_stores(rv, "iSerialNumber", newSVuv(desc->iSerialNumber));
    hv_stores(rv, "bNumConfigurations", newSVuv(desc->bNumConfigurations));
    return newRV_noinc((SV *) rv);
}

static SV *
version_to_RV(pTHX_ const struct libusb_version *version)
{
    HV *rv = newHV();
    hv_stores(rv, "major", newSVuv(version->major));
    hv_stores(rv, "minor", newSVuv(version->minor));
    hv_stores(rv, "micro", newSVuv(version->micro));
    hv_stores(rv, "nano", newSVuv(version->nano));
    hv_stores(rv, "rc", newSVpv(version->rc, 0));
    // "describe" key is for ABI compatibilty only => do not implement
    return newRV_noinc((SV *) rv);
}

static SV *
pointer_object(pTHX_ const char *class_name, void *pv)
{
    SV *rv = newSV(0);
    sv_setref_pv(rv, class_name, pv);
    return rv;
}




MODULE = USB::LibUSB::XS      PACKAGE = USB::LibUSB::XS

INCLUDE: const-xs.inc




  
######## Library initialization/deinitialization ##############################

  
MODULE = USB::LibUSB::XS		PACKAGE = USB::LibUSB::XS     PREFIX = libusb_

void
libusb_set_debug(USB::LibUSB::XS ctx, int level)

void
libusb_init(char *class)
PPCODE:
    libusb_context *ctx;
    int rv = libusb_init(&ctx);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(pointer_object(aTHX_ class, ctx));

void
libusb_exit(USB::LibUSB::XS ctx)

void
DESTROY(USB::LibUSB::XS ctx)
CODE:
    do_not_warn_unused(ctx);








######## Device handling and enumeration ######################################


MODULE = USB::LibUSB::XS		PACKAGE = USB::LibUSB::XS     PREFIX = libusb_
  
void
libusb_get_device_list(USB::LibUSB::XS ctx)
PPCODE:
    libusb_device **list;
    ssize_t num = libusb_get_device_list(ctx, &list);
    mXPUSHi(num);
    ssize_t i;
    for (i = 0; i < num; ++i) {
        SV *tmp = newSV(0);
        sv_setref_pv(tmp, "USB::LibUSB::XS::Device", (void *) list[i]);
        mXPUSHs(tmp);
    }
    if (num >= 0)
        libusb_free_device_list(list, 0);



MODULE = USB::LibUSB::XS      PACKAGE = USB::LibUSB::XS::Device       PREFIX = libusb_

void
DESTROY(USB::LibUSB::XS::Device dev)
CODE:
    do_not_warn_unused(dev);

unsigned
libusb_get_bus_number(USB::LibUSB::XS::Device dev)

unsigned
libusb_get_port_number(USB::LibUSB::XS::Device dev)

void
libusb_get_port_numbers(USB::LibUSB::XS::Device dev)
PPCODE:
    int len = 20;
    uint8_t port_numbers[len];
    int num = libusb_get_port_numbers(dev, port_numbers, len);
    mXPUSHi(num);
    int i;
    for (i = 0; i < num; ++i) {
        mXPUSHu(port_numbers[i]);
    }

# libusb_get_port_path is deprecated => do not implement

USB::LibUSB::XS::Device
libusb_get_parent(USB::LibUSB::XS::Device dev)


unsigned
libusb_get_device_address(USB::LibUSB::XS::Device dev)


int
libusb_get_device_speed(USB::LibUSB::XS::Device dev)


int
libusb_get_max_packet_size(USB::LibUSB::XS::Device dev, unsigned char endpoint)


int
libusb_get_max_iso_packet_size(USB::LibUSB::XS::Device dev, unsigned char endpoint)


USB::LibUSB::XS::Device
libusb_ref_device(USB::LibUSB::XS::Device dev)


void
libusb_unref_device(USB::LibUSB::XS::Device dev)

void
libusb_open(USB::LibUSB::XS::Device dev)
PPCODE:
    libusb_device_handle *handle;
    int rv = libusb_open(dev, &handle);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(pointer_object(aTHX_ "USB::LibUSB::XS::Device::Handle", handle));

MODULE = USB::LibUSB      PACKAGE = USB::LibUSB::XS     PREFIX = libusb_

USB::LibUSB::XS::Device::Handle
libusb_open_device_with_vid_pid(USB::LibUSB::XS ctx, unsigned vendor_id, unsigned product_id)

MODULE = USB::LibUSB      PACKAGE = USB::LibUSB::XS::Device::Handle     PREFIX = libusb_

void
DESTROY(USB::LibUSB::XS::Device::Handle handle)
CODE:
    do_not_warn_unused(handle);


void
libusb_close(USB::LibUSB::XS::Device::Handle handle)

USB::LibUSB::XS::Device
libusb_get_device(USB::LibUSB::XS::Device::Handle dev_handle)


void
libusb_get_configuration(USB::LibUSB::XS::Device::Handle dev)
PPCODE:
    int config;
    int rv = libusb_get_configuration(dev, &config);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHi(config);

int
libusb_set_configuration(USB::LibUSB::XS::Device::Handle dev, int configuration)

int
libusb_claim_interface(USB::LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_release_interface(USB::LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_set_interface_alt_setting(USB::LibUSB::XS::Device::Handle dev, int interface_number, int alternate_setting)

int
libusb_clear_halt(USB::LibUSB::XS::Device::Handle dev, unsigned endpoint)

int
libusb_reset_device(USB::LibUSB::XS::Device::Handle dev)

int
libusb_kernel_driver_active(USB::LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_detach_kernel_driver(USB::LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_attach_kernel_driver(USB::LibUSB::XS::Device::Handle dev, int interface_number)

int
libusb_set_auto_detach_kernel_driver(USB::LibUSB::XS::Device::Handle dev, int enable)





######## Miscellaneous ###########################################################


MODULE = USB::LibUSB::XS      PACKAGE = USB::LibUSB::XS

int
libusb_has_capability(unsigned capability)


const char *
libusb_error_name(int error_code)


void
libusb_get_version()
PPCODE:
    const struct libusb_version *version = libusb_get_version();
    mXPUSHs(version_to_RV(aTHX_ version));


int
libusb_setlocale(const char *locale)


const char *
libusb_strerror(int error_code)




######## USB descriptors ###########################################################

MODULE = USB::LibUSB::XS      PACKAGE = USB::LibUSB::XS::Device    PREFIX = libusb_

void
libusb_get_device_descriptor(USB::LibUSB::XS::Device dev)
PPCODE:
    struct libusb_device_descriptor desc;
    int rv = libusb_get_device_descriptor(dev, &desc);
    mXPUSHi(rv);
    // Function always succeeds since libusb 1.0.16
    mXPUSHs(device_descriptor_to_RV(aTHX_ &desc));


# Can't get ctx arg from libusb_device => Add as extra arg.

void
libusb_get_active_config_descriptor(USB::LibUSB::XS::Device dev, USB::LibUSB::XS ctx)
PPCODE:
    struct libusb_config_descriptor *config;
    int rv = libusb_get_active_config_descriptor(dev, &config);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(config_descriptor_to_RV(aTHX_ ctx, config));

    
void
libusb_get_config_descriptor(USB::LibUSB::XS::Device dev, USB::LibUSB::XS ctx, unsigned config_index)
PPCODE:
    struct libusb_config_descriptor *config;
    int rv = libusb_get_config_descriptor(dev, config_index, &config);
    mXPUSHi(rv);
    if (rv == 0) {
        mXPUSHs(config_descriptor_to_RV(aTHX_ ctx, config));
        libusb_free_config_descriptor(config);
    }


void
libusb_get_config_descriptor_by_value(USB::LibUSB::XS::Device dev, USB::LibUSB::XS ctx, unsigned bConfigurationValue)
PPCODE:
    struct libusb_config_descriptor *config;
    int rv = libusb_get_config_descriptor_by_value(dev, bConfigurationValue, &config);
    mXPUSHi(rv);
    if (rv == 0) {
        mXPUSHs(config_descriptor_to_RV(aTHX_ ctx, config));
        libusb_free_config_descriptor(config);
    }



MODULE = USB::LibUSB      PACKAGE = USB::LibUSB::XS::Device::Handle       PREFIX = libusb_

void
libusb_get_bos_descriptor(USB::LibUSB::XS::Device::Handle handle, USB::LibUSB::XS ctx)
PPCODE:
    struct libusb_bos_descriptor *bos;
    int rv = libusb_get_bos_descriptor(handle, &bos);
    mXPUSHi(rv);
    if (rv == 0) {
        mXPUSHs(bos_descriptor_to_RV(aTHX_ ctx, bos));
        libusb_free_bos_descriptor(bos);
    }
    

void
libusb_get_string_descriptor_ascii(USB::LibUSB::XS::Device::Handle dev, unsigned desc_index, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_string_descriptor_ascii(dev, desc_index, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


void
libusb_get_descriptor(USB::LibUSB::XS::Device::Handle dev, unsigned desc_type, unsigned desc_index, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_descriptor(dev, desc_type, desc_index, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


void
libusb_get_string_descriptor(USB::LibUSB::XS::Device::Handle dev, unsigned desc_index, unsigned langid, int length)
PPCODE:
    char *buffer;
    Newx(buffer, length, char);
    int rv = libusb_get_string_descriptor(dev, desc_index, langid, (unsigned char *) buffer, length);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(buffer, rv);
    Safefree(buffer);


######## Device hotplug event notification #########################################

# TODO


######## Asynchronous device I/O ###################################################

# TODO


######## Polling and timing ########################################################

# TODO


######## Synchronous device I/O ####################################################

MODULE = USB::LibUSB      PACKAGE = USB::LibUSB::XS::Device::Handle       PREFIX = libusb_

void
libusb_control_transfer_write(USB::LibUSB::XS::Device::Handle handle, unsigned bmRequestType, unsigned bRequest, unsigned wValue, unsigned wIndex, SV *data, unsigned timeout)
PPCODE:
    const char *bytes;
    STRLEN len;
    bytes = SvPV(data, len);
    if (len == 0)
        bytes = NULL;
    mXPUSHi(libusb_control_transfer(handle, bmRequestType, bRequest, wValue, wIndex, (unsigned char *) bytes, len, timeout));

void
libusb_control_transfer_read(USB::LibUSB::XS::Device::Handle handle, unsigned bmRequestType, unsigned bRequest, unsigned wValue, unsigned wIndex, unsigned length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int rv = libusb_control_transfer(handle, bmRequestType, bRequest, wValue, wIndex, (unsigned char *) data, length, timeout);
    mXPUSHi(rv);
    if (rv >= 0)
        mXPUSHp(data, rv);
    Safefree(data);

# Check whether endpoint is host-to-device in high-level code
void
libusb_bulk_transfer_write(USB::LibUSB::XS::Device::Handle handle, unsigned endpoint, SV *data, unsigned timeout)
PPCODE:
    STRLEN len;
    const char *bytes = SvPV(data, len);
    int transferred;
    int rv = libusb_bulk_transfer(handle, endpoint, (unsigned char *) bytes, len, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHi(transferred);

# Check whether endpoint is device-to-host in high-level code
void
libusb_bulk_transfer_read(USB::LibUSB::XS::Device::Handle handle, unsigned endpoint, int length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int transferred;
    int rv = libusb_bulk_transfer(handle, endpoint, (unsigned char *) data, length, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHp(data, transferred);
    Safefree(data);

# Check whether endpoint is host-to-device in high-level code
void
libusb_interrupt_transfer_write(USB::LibUSB::XS::Device::Handle handle, unsigned endpoint, SV *data, unsigned timeout)
PPCODE:
    STRLEN len;
    const char *bytes = SvPV(data, len);
    int transferred;
    int rv = libusb_interrupt_transfer(handle, endpoint, (unsigned char *) bytes, len, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHi(transferred);

# Check whether endpoint is device-to-host in high-level code
void
libusb_interrupt_transfer_read(USB::LibUSB::XS::Device::Handle handle, unsigned endpoint, int length, unsigned timeout)
PPCODE:
    char *data;
    Newx(data, length, char);
    int transferred;
    int rv = libusb_interrupt_transfer(handle, endpoint, (unsigned char *) data, length, &transferred, timeout);
    mXPUSHi(rv);
    if (rv == 0 || rv == LIBUSB_ERROR_TIMEOUT)
        mXPUSHp(data, transferred);
    Safefree(data);
    
