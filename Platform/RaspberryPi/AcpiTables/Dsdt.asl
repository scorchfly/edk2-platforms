/** @file
 *
 *  Differentiated System Definition Table (DSDT)
 *
 *  Copyright (c) 2020, Pete Batard <pete@akeo.ie>
 *  Copyright (c) 2018, Andrey Warkentin <andrey.warkentin@gmail.com>
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 **/

#include <IndustryStandard/Bcm2836.h>
#include <IndustryStandard/Bcm2836Gpio.h>
#include <IndustryStandard/Bcm2836Gpu.h>
#include <IndustryStandard/Bcm2836Pwm.h>
#include <Net/Genet.h>

#include "AcpiTables.h"

#define BCM_ALT0 0x4
#define BCM_ALT1 0x5
#define BCM_ALT2 0x6
#define BCM_ALT3 0x7
#define BCM_ALT4 0x3
#define BCM_ALT5 0x2

DefinitionBlock ("Dsdt.aml", "DSDT", 5, "MSFT", "EDK2", 2)
{
  Scope (\_SB_)
  {
    include ("Sdhc.asl")
    include ("Pep.asl")
#if (RPI_MODEL == 4)
    include ("Xhci.asl")
#endif

    Device (CPU0)
    {
      Name (_HID, "ACPI0007")
      Name (_UID, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
    }

    Device (CPU1)
    {
      Name (_HID, "ACPI0007")
      Name (_UID, 0x1)
      Method (_STA)
      {
        Return (0xf)
      }
    }

    Device (CPU2)
    {
      Name (_HID, "ACPI0007")
      Name (_UID, 0x2)
      Method (_STA)
      {
        Return (0xf)
      }
    }

    Device (CPU3)
    {
      Name (_HID, "ACPI0007")
      Name (_UID, 0x3)
      Method (_STA)
      {
        Return (0xf)
      }
    }

    // DWC OTG Controller
    Device (USB0)
    {
      Name (_HID, "BCM2848")
      Name (_CID, Package() { "DWC_OTG", "DWC2_OTG"})
      Name (_UID, 0x0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_USB_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_USB_INTERRUPT }
      })
      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_USB_OFFSET)
        Return (^RBUF)
      }
    }

    // Video Core 4 GPU
    Device (GPU0)
    {
      Name (_HID, "BCM2850")
      Name (_CID, "VC4")
      Name (_UID, 0x0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return(0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        // Memory and interrupt for the GPU
        MEMORY32FIXED (ReadWrite, 0, BCM2836_V3D_BUS_LENGTH, RM01)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_V3D_BUS_INTERRUPT }

        // HVS - Hardware Video Scalar
        MEMORY32FIXED (ReadWrite, 0, BCM2836_HVS_LENGTH, RM02)
        // The HVS interrupt is reserved by the VPU
        // Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_HVS_INTERRUPT }

        // PixelValve0 - DSI0 or DPI
        // MEMORY32FIXED (ReadWrite, BCM2836_PV0_BASE_ADDRESS, BCM2836_PV0_LENGTH, RM03)
        // Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_PV0_INTERRUPT }

        // PixelValve1 - DS1 or SMI
        // MEMORY32FIXED (ReadWrite, BCM2836_PV1_BASE_ADDRESS, BCM2836_PV1_LENGTH, RM04)
        // Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_PV1_INTERRUPT }

        // PixelValve2 - HDMI output - connected to HVS display FIFO 1
        MEMORY32FIXED (ReadWrite, 0, BCM2836_PV2_LENGTH, RM05)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_PV2_INTERRUPT }

        // HDMI registers
        MEMORY32FIXED (ReadWrite, 0, BCM2836_HDMI0_LENGTH, RM06)
        MEMORY32FIXED (ReadWrite, 0, BCM2836_HDMI1_LENGTH, RM07)
        // hdmi_int[0]
        // Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_HDMI0_INTERRUPT }
        // hdmi_int[1]
        // Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_HDMI1_INTERRUPT }

        // HDMI DDC connection
        I2CSerialBus (0x50,, 100000,, "\\_SB.I2C2",,,,)  // EDID
        I2CSerialBus (0x30,, 100000,, "\\_SB.I2C2",,,,)  // E-DDC Segment Pointer
      })
      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RM01, RB01, BCM2836_V3D_BUS_OFFSET)
        MEMORY32SETBASE (RBUF, RM02, RB02, BCM2836_HVS_OFFSET)
        MEMORY32SETBASE (RBUF, RM05, RB05, BCM2836_PV2_OFFSET)
        MEMORY32SETBASE (RBUF, RM06, RB06, BCM2836_HDMI0_OFFSET)
        MEMORY32SETBASE (RBUF, RM07, RB07, BCM2836_HDMI1_OFFSET)
        Return (^RBUF)
      }

      // GPU Power Management Component Data
      // Reference : https://github.com/Microsoft/graphics-driver-samples/wiki/Install-Driver-in-a-Windows-VM
      Method (PMCD, 0, Serialized)
      {
        Name (RBUF, Package ()
        {
          1,                  // Version
          1,                  // Number of graphics power components
          Package ()          // Power components package
          {
            Package ()        // GPU component package
            {
              0,              // Component Index
              0,              // DXGK_POWER_COMPONENT_MAPPING.ComponentType (0 = DXGK_POWER_COMPONENT_ENGINE)
              0,              // DXGK_POWER_COMPONENT_MAPPING.NodeIndex

              Buffer ()       // DXGK_POWER_RUNTIME_COMPONENT.ComponentGuid
              {               // 9B2D1E26-1575-4747-8FC0-B9EB4BAA2D2B
                0x26, 0x1E, 0x2D, 0x9B, 0x75, 0x15, 0x47, 0x47,
                0x8f, 0xc0, 0xb9, 0xeb, 0x4b, 0xaa, 0x2d, 0x2b
              },

              "VC4_Engine_00",// DXGK_POWER_RUNTIME_COMPONENT.ComponentName
              2,              // DXGK_POWER_RUNTIME_COMPONENT.StateCount

              Package ()      // DXGK_POWER_RUNTIME_COMPONENT.States[] package
              {
                Package ()   // F0
                {
                  0,         // DXGK_POWER_RUNTIME_STATE.TransitionLatency
                  0,         // DXGK_POWER_RUNTIME_STATE.ResidencyRequirement
                  1210000,   // DXGK_POWER_RUNTIME_STATE.NominalPower (microwatt)
                },

                Package ()   // F1 - Placeholder
                {
                  10000,     // DXGK_POWER_RUNTIME_STATE.TransitionLatency
                  10000,     // DXGK_POWER_RUNTIME_STATE.ResidencyRequirement
                  4,         // DXGK_POWER_RUNTIME_STATE.NominalPower
                },
              }
            }
          }
        })
        Return (RBUF)
      }
    }

    // PiQ Mailbox Driver
    Device (RPIQ)
    {
      Name (_HID, "BCM2849")
      Name (_CID, "RPIQ")
      Name (_UID, 0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_MBOX_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_MBOX_INTERRUPT }
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_MBOX_OFFSET)
        Return (^RBUF)
      }
    }

    // VCHIQ Driver
    Device (VCIQ)
    {
      Name (_HID, "BCM2835")
      Name (_CID, "VCIQ")
      Name (_UID, 0)
      Name (_CCA, 0x0)
      Name (_DEP, Package() { \_SB.RPIQ })
      Method (_STA)
      {
         Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_VCHIQ_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_VCHIQ_INTERRUPT }
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_VCHIQ_OFFSET)
        Return (^RBUF)
      }
    }

    // VC Shared Memory Driver
    Device (VCSM)
    {
      Name (_HID, "BCM2856")
      Name (_CID, "VCSM")
      Name (_UID, 0)
      Name (_CCA, 0x0)
      Name (_DEP, Package() { \_SB.VCIQ })
      Method (_STA)
      {
        Return (0xf)
      }
    }

    // Description: GPIO
    Device (GPI0)
    {
      Name (_HID, "BCM2845")
      Name (_CID, "BCMGPIO")
      Name (_UID, 0x0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return(0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, GPIO_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { BCM2386_GPIO_INTERRUPT0, BCM2386_GPIO_INTERRUPT1 }
      })
      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, GPIO_OFFSET)
        Return (^RBUF)
      }
    }

#if (RPI_MODEL == 4)
    Device (ETH0)
    {
      Name (_HID, "BCM6E4E")
      Name (_CID, "BCM6E4E")
      Name (_UID, 0x0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Method (_CRS, 0x0, Serialized)
      {
        Name (RBUF, ResourceTemplate ()
        {
          // No need for MEMORY32SETBASE on Genet as we have a straight base address constant
          MEMORY32FIXED (ReadWrite, GENET_BASE_ADDRESS, GENET_LENGTH, )
          Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { GENET_INTERRUPT0, GENET_INTERRUPT1 }
        })
        Return (RBUF)
      }
      Name (_DSD, Package () {
        ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package () {
          Package () { "brcm,max-dma-burst-size", 0x08 },
          Package () { "phy-mode", "rgmii-rxid" },
        }
      })
    }
#endif

    // Description: I2C
    Device (I2C1)
    {
      Name (_HID, "BCM2841")
      Name (_CID, "BCMI2C")
      Name (_UID, 0x1)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return(0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_I2C1_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { BCM2836_I2C1_INTERRUPT }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig (Exclusive, PullUp, BCM_ALT0, "\\_SB.GPI0", 0, ResourceConsumer,) {2, 3}
        //
        VendorLong ()      // Length = 0x31
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1D, 0x00, 0x01, 0x10, 0x00, 0x01,  // /.......
          /* 0018 */  0x04, 0x00, 0x12, 0x00, 0x00, 0x16, 0x00, 0x20,  // ........
          /* 0020 */  0x00, 0x00, 0x00, 0x02, 0x00, 0x03, 0x00, 0x5C,  // ........
          /* 0028 */  0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50, 0x49, 0x30,  // _SB.GPI0
          /* 0030 */  0x00                                             // .
        }
      })
      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_I2C1_OFFSET)
        Return (^RBUF)
      }
    }

    // I2C2 is the HDMI DDC connection
    Device (I2C2)
    {
      Name (_HID, "BCM2841")
      Name (_CID, "BCMI2C")
      Name (_UID, 0x2)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_I2C2_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { BCM2836_I2C2_INTERRUPT }
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_I2C2_OFFSET)
        Return (^RBUF)
      }
    }

    // SPI
    Device (SPI0)
    {
      Name (_HID, "BCM2838")
      Name (_CID, "BCMSPI0")
      Name (_UID, 0x0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_SPI0_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { BCM2836_SPI0_INTERRUPT }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig (Exclusive, PullDown, BCM_ALT0, "\\_SB.GPI0", 0, ResourceConsumer, ) {9, 10, 11} // MISO, MOSI, SCLK
        VendorLong ()      // Length = 0x33
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1F, 0x00, 0x01, 0x10, 0x00, 0x02,  // /.......
          /* 0018 */  0x04, 0x00, 0x12, 0x00, 0x00, 0x18, 0x00, 0x22,  // ......."
          /* 0020 */  0x00, 0x00, 0x00, 0x09, 0x00, 0x0A, 0x00, 0x0B,  // ........
          /* 0028 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50,  // .\_SB.GP
          /* 0030 */  0x49, 0x30, 0x00                                 // I0.
        }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig (Exclusive, PullUp, BCM_ALT0, "\\_SB.GPI0", 0, ResourceConsumer, ) {8}     // CE0
        VendorLong ()      // Length = 0x2F
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1B, 0x00, 0x01, 0x10, 0x00, 0x01,  // /.......
          /* 0018 */  0x04, 0x00, 0x12, 0x00, 0x00, 0x14, 0x00, 0x1E,  // ........
          /* 0020 */  0x00, 0x00, 0x00, 0x08, 0x00, 0x5C, 0x5F, 0x53,  // .....\_S
          /* 0028 */  0x42, 0x2E, 0x47, 0x50, 0x49, 0x30, 0x00         // B.GPI0.
        }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig (Exclusive, PullUp, BCM_ALT0, "\\_SB.GPI0", 0, ResourceConsumer, ) {7}     // CE1
        VendorLong ()      // Length = 0x2F
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1B, 0x00, 0x01, 0x10, 0x00, 0x01,  // /.......
          /* 0018 */  0x04, 0x00, 0x12, 0x00, 0x00, 0x14, 0x00, 0x1E,  // ........
          /* 0020 */  0x00, 0x00, 0x00, 0x07, 0x00, 0x5C, 0x5F, 0x53,  // .....\_S
          /* 0028 */  0x42, 0x2E, 0x47, 0x50, 0x49, 0x30, 0x00         // B.GPI0.
        }
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_SPI0_OFFSET)
        Return (^RBUF)
      }
    }

    Device (SPI1)
    {
      Name (_HID, "BCM2839")
      Name (_CID, "BCMAUXSPI")
      Name (_UID, 0x1)
      Name (_CCA, 0x0)
      Name (_DEP, Package() { \_SB.RPIQ })
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        MEMORY32FIXED (ReadWrite, 0, BCM2836_SPI1_LENGTH, RMEM)
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared,) { BCM2836_SPI1_INTERRUPT }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig(Exclusive, PullDown, BCM_ALT4, "\\_SB.GPI0", 0, ResourceConsumer, ) {19, 20, 21} // MISO, MOSI, SCLK
        VendorLong ()      // Length = 0x33
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1F, 0x00, 0x01, 0x10, 0x00, 0x02,  // /.......
          /* 0018 */  0x03, 0x00, 0x12, 0x00, 0x00, 0x18, 0x00, 0x22,  // ......."
          /* 0020 */  0x00, 0x00, 0x00, 0x13, 0x00, 0x14, 0x00, 0x15,  // ........
          /* 0028 */  0x00, 0x5C, 0x5F, 0x53, 0x42, 0x2E, 0x47, 0x50,  // .\_SB.GP
          /* 0030 */  0x49, 0x30, 0x00                                 // I0.
        }

        //
        // MsftFunctionConfig is encoded as the VendorLong.
        //
        // MsftFunctionConfig(Exclusive, PullDown, BCM_ALT4, "\\_SB.GPI0", 0, ResourceConsumer, ) {16} // CE2
        VendorLong ()      // Length = 0x2F
        {
          /* 0000 */  0x00, 0x60, 0x44, 0xD5, 0xF3, 0x1F, 0x11, 0x60,  // .`D....`
          /* 0008 */  0x4A, 0xB8, 0xB0, 0x9C, 0x2D, 0x23, 0x30, 0xDD,  // J...-#0.
          /* 0010 */  0x2F, 0x8D, 0x1B, 0x00, 0x01, 0x10, 0x00, 0x02,  // /.......
          /* 0018 */  0x03, 0x00, 0x12, 0x00, 0x00, 0x14, 0x00, 0x1E,  // ........
          /* 0020 */  0x00, 0x00, 0x00, 0x10, 0x00, 0x5C, 0x5F, 0x53,  // .....\_S
          /* 0028 */  0x42, 0x2E, 0x47, 0x50, 0x49, 0x30, 0x00         // B.GPI0.
        }
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RMEM, RBAS, BCM2836_SPI1_OFFSET)
        Return (^RBUF)
      }
    }

    // SPI2 has no pins on GPIO header
    // Device (SPI2)
    // {
    //   Name (_HID, "BCM2839")
    //   Name (_CID, "BCMAUXSPI")
    //   Name (_UID, 0x2)
    //   Name (_CCA, 0x0)
    //   Name (_DEP, Package() { \_SB.RPIQ })
    //   Method (_STA)
    //   {
    //     Return (0xf)     // Disabled
    //   }
    //   Method (_CRS, 0x0, Serialized)
    //   {
    //     Name (RBUF, ResourceTemplate ()
    //     {
    //       MEMORY32FIXED (ReadWrite, BCM2836_SPI2_BASE_ADDRESS, BCM2836_SPI2_LENGTH, RMEM)
    //       Interrupt (ResourceConsumer, Level, ActiveHigh, Shared,) { BCM2836_SPI2_INTERRUPT }
    //     })
    //     Return (RBUF)
    //   }
    // }

    // PWM Driver
    Device (PWM0)
    {
      Name (_HID, "BCM2844")
      Name (_CID, "BCM2844")
      Name (_UID, 0)
      Name (_CCA, 0x0)
      Method (_STA)
      {
        Return (0xf)
      }
      Name (RBUF, ResourceTemplate ()
      {
        // DMA channel 11 control
        MEMORY32FIXED (ReadWrite, 0, BCM2836_PWM_DMA_LENGTH, RM01)
        // PWM control
        MEMORY32FIXED (ReadWrite, 0, BCM2836_PWM_CTRL_LENGTH, RM02)
        // PWM control bus
        MEMORY32FIXED (ReadWrite, BCM2836_PWM_BUS_BASE_ADDRESS, BCM2836_PWM_BUS_LENGTH, )
        // PWM control uncached
        MEMORY32FIXED (ReadWrite, BCM2836_PWM_CTRL_UNCACHED_BASE_ADDRESS, BCM2836_PWM_CTRL_UNCACHED_LENGTH, )
        // PWM clock control
        MEMORY32FIXED (ReadWrite, 0, BCM2836_PWM_CLK_LENGTH, RM03)
        // Interrupt DMA channel 11
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { BCM2836_DMA_INTERRUPT }
        // DMA channel 11, DREQ 5 for PWM
        FixedDMA (5, 11, Width32Bit, )
      })

      Method (_CRS, 0x0, Serialized)
      {
        MEMORY32SETBASE (RBUF, RM01, RB01, BCM2836_PWM_DMA_OFFSET)
        MEMORY32SETBASE (RBUF, RM02, RB02, BCM2836_PWM_CTRL_OFFSET)
        MEMORY32SETBASE (RBUF, RM03, RB03, BCM2836_PWM_CLK_OFFSET)
        Return (^RBUF)
      }
    }

    include ("Uart.asl")
    include ("Rhpx.asl")
  }
}
