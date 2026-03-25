//
//  Identifiable+BagelModels.swift
//  Bagel
//

import Foundation

extension BagelProjectController: Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

extension BagelDeviceController: Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

extension BagelPacket: Identifiable {
    public var id: String { packetId ?? String(ObjectIdentifier(self).hashValue) }
}

extension KeyValue: Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
