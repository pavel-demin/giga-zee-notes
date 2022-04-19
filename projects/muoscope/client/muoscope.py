#!/usr/bin/env python

# Control program for the MuoScope system
# Copyright (C) 2018  Pavel Demin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
import struct
import time

from functools import partial

import numpy as np
np.set_printoptions(formatter = {'int':hex})

from PyQt5.uic import loadUiType
from PyQt5.QtCore import QRegExp, QTimer, QSettings
from PyQt5.QtGui import QRegExpValidator
from PyQt5.QtWidgets import QApplication, QMainWindow, QMenu, QVBoxLayout, QSizePolicy, QMessageBox, QWidget, QLabel, QLineEdit, QCheckBox, QSpinBox, QPushButton, QFileDialog, QDialog
from PyQt5.QtNetwork import QAbstractSocket, QTcpSocket

Ui_MuoScope, QMainWindow = loadUiType('muoscope.ui')

class MuoScope(QMainWindow, Ui_MuoScope):
  def __init__(self):
    super(MuoScope, self).__init__()
    self.setupUi(self)
    # IP address validator
    rx = QRegExp('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')
    self.addrValue.setValidator(QRegExpValidator(rx, self.addrValue))
    # state variables
    self.idle = True
    self.reading = False
    # buffer and offset for the incoming samples
    self.buffer = bytearray(84)
    self.offset = 0
    self.data = np.frombuffer(self.buffer, np.float32)
    # configure widgets
    self.discValue = {}
    self.discFeedback = {}
    self.monoValue = {}
    self.monoFeedback = {}
    self.dlyValue = {}
    for i in range(0, 8):
      label = QLabel('CH' + str(i))
      label.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
      self.discLayout.addWidget(label, (i // 4) * 3 + 0, i % 4)
      self.discValue[i] = QSpinBox()
      self.discValue[i].setMaximum(511)
      self.discValue[i].valueChanged.connect(partial(self.set_disc, i))
      self.discLayout.addWidget(self.discValue[i], (i // 4) * 3 + 1, i % 4)
      self.discFeedback[i] = QLineEdit()
      self.discFeedback[i].setReadOnly(True)
      self.discLayout.addWidget(self.discFeedback[i], (i // 4) * 3 + 2, i % 4)
    for i in range(0, 8):
      label = QLabel('CH' + str(i))
      label.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
      self.monoLayout.addWidget(label, (i // 4) * 3 + 0, i % 4)
      self.monoValue[i] = QSpinBox()
      self.monoValue[i].setMaximum(1023)
      self.monoValue[i].valueChanged.connect(partial(self.set_mono, i))
      self.monoLayout.addWidget(self.monoValue[i], (i // 4) * 3 + 1, i % 4)
      self.monoFeedback[i] = QLineEdit()
      self.monoFeedback[i].setReadOnly(True)
      self.monoLayout.addWidget(self.monoFeedback[i], (i // 4) * 3 + 2, i % 4)
    for i in range(0, 4):
      label = QLabel(chr(ord('A') + i))
      label.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
      self.dlyLayout.addWidget(label, 0, i)
      self.dlyValue[i] = QSpinBox()
      self.dlyValue[i].setMaximum(15)
      self.dlyValue[i].valueChanged.connect(partial(self.set_dly, i))
      self.dlyLayout.addWidget(self.dlyValue[i], 1, i)
    self.voltageValue.valueChanged.connect(partial(self.set_hv, 0))
    self.currentValue.valueChanged.connect(partial(self.set_hv, 1))
    self.stateValue.stateChanged.connect(self.set_state)
    self.wndValue.valueChanged.connect(self.set_wnd)
    self.cutValue.valueChanged.connect(self.set_cut)
    # read settings
    settings = QSettings('muoscope.ini', QSettings.IniFormat)
    self.read_cfg_settings(settings)
    # create TCP socket
    self.socket = QTcpSocket(self)
    self.socket.connected.connect(self.connected)
    self.socket.readyRead.connect(self.read_data)
    self.socket.error.connect(self.display_error)
    # connect signals from widgets
    self.connectButton.clicked.connect(self.start)
    self.writeButton.clicked.connect(self.write_cfg)
    self.readButton.clicked.connect(self.read_cfg)
    # create timers
    self.startTimer = QTimer(self)
    self.startTimer.timeout.connect(self.timeout)
    self.adcTimer = QTimer(self)
    self.adcTimer.timeout.connect(self.get_adc)

  def start(self):
    if self.idle:
      self.connectButton.setEnabled(False)
      self.socket.connectToHost(self.addrValue.text(), 1001)
      self.startTimer.start(5000)
    else:
      self.stop()

  def stop(self):
    self.adcTimer.stop()
    self.idle = True
    self.socket.abort()
    self.connectButton.setText('Connect')
    self.connectButton.setEnabled(True)

  def timeout(self):
    self.display_error('timeout')

  def connected(self):
    self.startTimer.stop()
    self.idle = False
    self.connectButton.setText('Disconnect')
    self.connectButton.setEnabled(True)
    for i, item in self.discValue.items():
      self.set_disc(i, item.value())
    for i, item in self.monoValue.items():
      self.set_mono(i, item.value())
    self.set_hv(0, self.voltageValue.value())
    self.set_hv(1, self.currentValue.value())
    self.set_state(self.stateValue.isChecked())
    self.set_dly(0)
    self.set_wnd(self.wndValue.value())
    self.set_cut(self.cutValue.value())
    self.adcTimer.start(200)

  def timeout(self):
    self.display_error('timeout')

  def display_error(self, socketError):
    self.startTimer.stop()
    if socketError == 'timeout':
      QMessageBox.information(self, 'MuoScope', 'Error: connection timeout.')
    else:
      QMessageBox.information(self, 'MuoScope', 'Error: %s.' % self.socket.errorString())
    self.stop()

  def read_data(self):
    while(self.socket.bytesAvailable() > 0):
      if not self.reading:
        self.socket.readAll()
        return
      size = self.socket.bytesAvailable()
      limit = 84
      if self.offset + size < limit:
        self.buffer[self.offset:self.offset + size] = self.socket.read(size)
        self.offset += size
      else:
        self.buffer[self.offset:limit] = self.socket.read(limit - self.offset)
        self.reading = False
        for i, item in self.discFeedback.items():
          item.setText('%.3f' % self.data[i + i // 2 * 2 + 0])
        for i, item in self.monoFeedback.items():
          item.setText('%.3f' % self.data[i + i // 2 * 2 + 2])
        self.voltageFeedback.setText('%.3f' % self.data[17])
        self.currentFeedback.setText('%.3f' % self.data[16])
        self.stateFeedback.setText('%.0f' % self.data[20])

  def get_adc(self):
    if self.idle: return
    self.reading = True
    self.socket.write(struct.pack('<I', 0<<24))

  def set_disc(self, channel, value):
    if self.idle: return
    self.socket.write(struct.pack('<I', 1<<24 | int(channel + channel // 2 * 2 + 0)<<16 | int(value)))

  def set_mono(self, channel, value):
    if self.idle: return
    self.socket.write(struct.pack('<I', 1<<24 | int(channel + channel // 2 * 2 + 2)<<16 | int(value)))

  def set_hv(self, channel, value):
    if self.idle: return
    self.socket.write(struct.pack('<I', 2<<24 | int(channel)<<16 | int(value)))

  def set_state(self, state):
    if self.idle: return
    self.socket.write(struct.pack('<I', 3<<24 | int(self.stateValue.isChecked())))

  def set_dly(self, value):
    if self.idle: return
    value = self.dlyValue[3].value() << 12 | self.dlyValue[2].value() << 8 | self.dlyValue[1].value() << 4 | self.dlyValue[0].value()
    self.socket.write(struct.pack('<I', 4<<24 | int(value)))

  def set_wnd(self, value):
    if self.idle: return
    self.socket.write(struct.pack('<I', 5<<24 | int(value)))

  def set_cut(self, value):
    if self.idle: return
    self.socket.write(struct.pack('<I', 6<<24 | int(value)))

  def write_cfg(self):
    dialog = QFileDialog(self, 'Write configuration settings', '.', '*.ini')
    dialog.setDefaultSuffix('ini')
    dialog.selectFile('muoscope.ini')
    dialog.setAcceptMode(QFileDialog.AcceptSave)
    dialog.setOptions(QFileDialog.DontConfirmOverwrite)
    if dialog.exec() == QDialog.Accepted:
      name = dialog.selectedFiles()
      settings = QSettings(name[0], QSettings.IniFormat)
      self.write_cfg_settings(settings)

  def read_cfg(self):
    dialog = QFileDialog(self, 'Read configuration settings', '.', '*.ini')
    dialog.setDefaultSuffix('ini')
    dialog.selectFile('muoscope.ini')
    dialog.setAcceptMode(QFileDialog.AcceptOpen)
    if dialog.exec() == QDialog.Accepted:
      name = dialog.selectedFiles()
      settings = QSettings(name[0], QSettings.IniFormat)
      self.read_cfg_settings(settings)

  def write_cfg_settings(self, settings):
    settings.setValue('addr', self.addrValue.text())
    for i, item in self.discValue.items():
      settings.setValue('disc_%d' % i, item.value())
    for i, item in self.monoValue.items():
      settings.setValue('mono_%d' % i, item.value())
    for i, item in self.dlyValue.items():
      settings.setValue('dly_%d' % i, item.value())
    settings.setValue('voltage', self.voltageValue.value())
    settings.setValue('current', self.currentValue.value())
    settings.setValue('cut', self.cutValue.value())
    settings.setValue('wnd', self.wndValue.value())

  def read_cfg_settings(self, settings):
    self.addrValue.setText(settings.value('addr', '192.168.42.1'))
    for i, item in self.discValue.items():
      item.setValue(settings.value('disc_%d' % i, 100, type = int))
    for i, item in self.monoValue.items():
      item.setValue(settings.value('mono_%d' % i, 100, type = int))
    for i, item in self.dlyValue.items():
      item.setValue(settings.value('dly_%d' % i, 0, type = int))
    self.voltageValue.setValue(settings.value('voltage', 0, type = int))
    self.currentValue.setValue(settings.value('current', 4095, type = int))
    self.cutValue.setValue(settings.value('cut', 1, type = int))
    self.wndValue.setValue(settings.value('wnd', 3, type = int))

app = QApplication(sys.argv)
window = MuoScope()
window.show()
sys.exit(app.exec_())
