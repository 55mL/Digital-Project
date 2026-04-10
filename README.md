# Digital-Project

# Traffic Light Brake Reaction Game Using Nexys A7 FPGA

โปรเจควิชา Digital Design จำลองเกม เหยียบเบรคตามสัญญาณไฟจราจร บนบอร์ด Nexys A7-100T โดยผู้เล่นต้องตอบสนองต่อสีไฟจราจรที่สุ่มขึ้นมา ทั้งการเอียงบอร์ดและการกดสวิตช์ให้ถูกต้องภายในเวลาที่กำหนด

---

## ภาพรวมเกม

ผู้เล่นจะเห็นไฟจราจรสุ่มขึ้นบน RGB LED บนบอร์ด (สีเขียว / เหลือง / แดง) พร้อมนับถอยหลังบน 7-segment display และแถบ LED 16 ดวงบนสวิตช์ ผู้เล่นต้องทำท่าทางตามเงื่อนไขของแต่ละสีให้ถูกต้อง และ **ค้างไว้ 1 วินาที** ก่อนเวลาหมด หากผ่านจะได้คะแนนและด่านจะยากขึ้น หากไม่ผ่านเกมจะจบและแสดง High Score

---

## อุปกรณ์ที่ใช้

| อุปกรณ์ | รายละเอียด |
|---|---|
| บอร์ด FPGA | Digilent Nexys A7-100T |
| EDA Tool | Xilinx Vivado |
| ภาษา HDL | VHDL |

---

## โครงสร้างโปรเจค

```
Digital-Project/
├── Design Sources/
│   ├── countdown_level/
│   │   ├── countdown_level.vhd     
│   │   ├── countdown7seg.vhd       
│   │   ├── clock_divider.vhd       
│   │   └── bin_to_7seg.vhd         
│   ├── NexysDdrUserDemo/
│   │   ├── top.vhd                 
│   │   ├── RandomColor.vhd         
│   │   ├── sSegDemo.vhd            
│   │   ├── sSegDisplay.vhd         
│   │   ├── AccelerometerCtl.vhd    
│   │   ├── AccelArithmetics.vhd    
│   │   ├── ADXL362Ctrl.vhd         
│   │   └── SPI_If.vhd              
│   ├── Press.vhd                   
│   ├── Gameover.vhd                
│   └── HighScore.vhd               
├── Constraints/
│   ├── constrs_1/
│   │   ├── constraints.xdc         
│   │   └── Constraint.xdc          
│   └── Nexys-A7-100T-Master.xdc    
└── README.md
```

---

## กฎของเกม

### 🟢 ไฟเขียว
- เอียงบอร์ด **45 องศา** (ค่า accelerometer X อยู่ในช่วง 370–398)
- กด **Switch 15 = ON** และ **Switch 0 = OFF**

### 🟡 ไฟเหลือง
- เอียงบอร์ด **45 องศา** (ค่า accelerometer X อยู่ในช่วง 370–398)
- กด **Switch 0 = ON** และ **Switch 15 = OFF**

### 🔴 ไฟแดง
- เอียงบอร์ด **90 องศา** (ค่า accelerometer X อยู่ในช่วง 240–270)
- กด **Switch 15 = ON** และ **Switch 0 = ON**

>  ต้องค้างท่าทางทุกเงื่อนไขไว้อย่างน้อย **1 วินาที** และทำให้เสร็จก่อนเวลาหมด

---

## การทำงานของระบบ

```
[PRESS]
  ↓ กดปุ่มบนบอร์ด
[START]
  ↓ ระบบสุ่มสีไฟจราจร
[ไฟจราจรสว่าง บน LED17]
  ↓ เริ่มนับถอยหลัง (7-seg + LED bar)
[ผู้เล่นทำท่าทางตามเงื่อนไข]
  ↓
[PASS] → เพิ่ม Score +1 → เพิ่มความยาก (ลดเวลา 500ms) → สุ่มไฟใหม่
  หรือ
[FAIL] → แสดง High Score → จบเกม
```

### ระบบเพิ่มความยาก
- เริ่มต้นที่ **3,000 ms** (3 วินาที)
- ทุกครั้งที่ผ่านด่าน เวลาจะ **ลดลง 500 ms**
- เวลาขั้นต่ำสุดถูก cap ไว้ที่ **9,990 ms**

### การแสดงผลบน 7-Segment
| สถานะ | ข้อความ |
|---|---|
| รอผู้เล่น | `PRESS` |
| เริ่มเกม | `START` |
| กำลังนับถอยหลัง | `X.XX` วินาที (digit 3–0) |
| ผ่านด่าน | `PASS` |
| ไม่ผ่าน | `FAIL` |
| จบเกม | `GAME OVER` |
| สรุปคะแนน | `HI XXXX` |

---

## Constraints และการ Map Pin

| สัญญาณ | Pin | คำอธิบาย |
|---|---|---|
| `clk` | E3 | 100 MHz system clock |
| `rstn_i` / `reset` | C12 / M18 | CPU Reset button |
| `btnc_i` | N17 | กดสุ่มสีไฟ |
| `disp_seg_o[7:0]` | T10, R10, K16, K13, P15, T11, L18, H15 | Cathode 7-seg |
| `disp_an_o[7:0]` | J17, J18, T9, J14, P14, T14, K2, U13 | Anode 7-seg |
| `led_o[15:0]` / `led_r[15:0]` | V11–H17 | User LEDs 16 ดวง |
| `led17_r/g/b` | N16, R11, G14 | RGB LED LD17 |
| `miso/mosi/sclk/ss` | E15, F14, F15, D15 | SPI Accelerometer |

---

## วิธีการใช้งาน

1. เปิด Vivado และสร้าง Project ใหม่ เลือก board **Nexys A7-100T**
2. เพิ่มไฟล์ `.vhd` ทั้งหมดใน `Design Sources/` เข้า project
3. เพิ่มไฟล์ constraints `.xdc` ที่เหมาะสม
4. กำหนด top-level entity เป็น `Nexys4DdrUserDemo`
5. Run Synthesis → Implementation → Generate Bitstream
6. Program บอร์ด
7. กด **CPU RESET** เพื่อรีเซตระบบ
8. 7-seg จะแสดง **PRESS** → กดปุ่ม **BTNC** เพื่อเริ่มเกม
9. ดูสีไฟบน **LED17** และทำท่าทางตามเงื่อนไขให้ถูกต้อง

---

## ผู้พัฒนา

โปรเจคนี้เป็นส่วนหนึ่งของวิชา Digital Design  
