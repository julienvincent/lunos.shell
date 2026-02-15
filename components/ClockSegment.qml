 import Quickshell
 import QtQuick
 
 Row {
   property string fontFamily: ""
 
   spacing: 8

   SystemClock {
     id: clock
     precision: SystemClock.Minutes
   }
 
   Text {
     id: clockDate
     color: "#ebdbb2" // fg0
     font.family: fontFamily
     font.pixelSize: 12
     font.bold: true
     text: Qt.formatDateTime(clock.date, "ddd dd")
   }
 
   Text {
     id: clockTime
     color: "#ebdbb2" // fg0
     font.family: fontFamily
     font.pixelSize: 12
     font.bold: true
     text: Qt.formatDateTime(clock.date, "HH:mm")
   }
 }
