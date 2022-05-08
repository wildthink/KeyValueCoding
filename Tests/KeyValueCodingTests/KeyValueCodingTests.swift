import XCTest
import KeyValueCoding
//@testable import KeyValueCoding


enum UserType {
    case none
    case guest
    case user
    case admin
}

class Info: Equatable {
    let phone: String
    let email: String
    
    init(phone: String, email: String) {
        self.phone = phone
        self.email = email
    }
    
    static func == (lhs: Info, rhs: Info) -> Bool {
        lhs.phone == rhs.phone && lhs.email == rhs.email
    }
}

protocol UserProtocol: KeyValueCoding {
    var id: Int { get }
    var name: String? { get }
    var type: UserType { get }
    var array: [Int] { get }
    var info: Info { get }
}

class UserClass: UserProtocol {
    let id = 0
    let name: String? = nil
    let type: UserType = .none
    let array: [Int] = [Int]()
    let info: Info = Info(phone: "", email: "")
}

class UserClass2: UserClass {
    let promoCode: Int = 0
}

class UserClassObjC: NSObject, UserProtocol {
    @objc let id = 0
    @objc let name: String? = nil
    let type: UserType = .none
    @objc let array: [Int] = [Int]()
    let info: Info = Info(phone: "", email: "")
}

struct UserStruct: UserProtocol {
    let id = 0
    let name: String? = nil
    let type: UserType = .none
    let array: [Int] = [Int]()
    let info: Info = Info(phone: "", email: "")
}

protocol BookProtocol: KeyValueCoding {
    var title: String {get set}
}

struct Book: BookProtocol {
    var title: String = ""
    var ISBN: Int = 0
    var description: String = ""
}

protocol SongProtocol: KeyValueCoding {
    var name: String { get set }
}

struct Song: SongProtocol {
    var name: String
}

final class KeyValueCodingTests: XCTestCase {
    
    func test_keyValueCoding<T: UserProtocol>(_ instance: inout T, kind: Metadata.Kind, propertiesCount: Int = 5) {
        // Metadata
        
        let metadata = swift_metadata(of: instance)
        XCTAssert(swift_metadata(of: T.self).kind == kind)
        XCTAssert(metadata.kind == kind)
        XCTAssert(instance.metadata.kind == kind)
        
        XCTAssert(metadata.properties.count == propertiesCount)
        XCTAssert(metadata.name.contains("User"))
        if kind == .class {
            XCTAssert(metadata.size == 8)
        }
        else {
            XCTAssert(metadata.size == 48)
        }
        
        let property = instance.metadata.properties[0]
        XCTAssert(property.name == "id")
        XCTAssert(property.type is Int.Type)
        XCTAssert(property.isStrong)
        XCTAssert(property.isVar == false)
        
        // Set value
        
        let array = [1, 2, 3]
        let info = Info(phone: "1234567890", email: "mail@domain.com")
        
        swift_setValue(1, to: &instance, key: "id")
        swift_setValue("Bob", to: &instance, key: "name")
        swift_setValue(UserType.admin, to: &instance, key: "type")
        swift_setValue(array, to: &instance, key: "array")
        swift_setValue(info, to: &instance, key: "info")
        XCTAssert(instance.id == 1)
        XCTAssert(instance.name == "Bob")
        XCTAssert(instance.type == .admin)
        XCTAssert(instance.array == array)
        XCTAssert(instance.info == info)
        
        instance.setValue(2, key: "id")
        instance.setValue(nil, key: "name")
        instance.setValue(UserType.guest, key: "type")
        instance.setValue([], key: "array")
        instance.setValue(Info(phone:"", email: ""), key: "info")
        XCTAssert(instance.id == 2)
        XCTAssert(instance.name == nil)
        XCTAssert(instance.type == .guest)
        XCTAssert(instance.array == [])
        XCTAssert(instance.info == Info(phone:"", email: ""))
        
        instance["id"] = 3
        instance["name"] = "Alice"
        instance["type"] = UserType.user
        instance["array"] = array
        instance["info"] = info
        XCTAssert(instance.id == 3)
        XCTAssert(instance.name == "Alice")
        XCTAssert(instance.type == .user)
        XCTAssert(instance.array == array)
        XCTAssert(instance.info == info)
        
        // Get value
        
        XCTAssertNil(swift_value(of: &instance, key: "undefined"))
        XCTAssert(swift_value(of: &instance, key: "id") as? Int == 3)
        XCTAssert(swift_value(of: &instance, key: "name") as? String == "Alice")
        XCTAssert(swift_value(of: &instance, key: "type") as? UserType == .user)
        XCTAssert(swift_value(of: &instance, key: "array") as? [Int] == array)
        XCTAssert(swift_value(of: &instance, key: "info") as? Info == info)
        
        XCTAssertNil(instance.value(key: "undefined"))
        XCTAssert(instance.value(key: "id") as? Int == 3)
        XCTAssert(instance.value(key: "name") as? String == "Alice")
        XCTAssert(instance.value(key: "type") as? UserType == .user)
        XCTAssert(instance.value(key: "array") as? [Int] == array)
        XCTAssert(instance.value(key: "info") as? Info == info)
        
        XCTAssertNil(instance["undefined"])
        XCTAssert(instance["id"] as? Int == 3)
        XCTAssert(instance["name"] as? String == "Alice")
        XCTAssert(instance["type"] as? UserType == .user)
        XCTAssert(instance["array"] as? [Int] == array)
        XCTAssert(instance["info"] as? Info == info)
    }
    
    func test_class() {
        var user = UserClass()
        test_keyValueCoding(&user, kind: .class)
        
        // Existential
        var p: UserProtocol = user
        swift_setValue(777, to: &p, key: "id")
        XCTAssert(swift_value(of: &p, key: "id") as? Int == 777)
    }
    
    func test_class_inheritance() {
        var user = UserClass2()
        test_keyValueCoding(&user, kind: .class, propertiesCount: 6)
        
        user["promoCode"] = 100
        XCTAssert(user["promoCode"] as? Int == 100)
    }
    
    func test_class_objc() {
        var user = UserClassObjC()
        test_keyValueCoding(&user, kind: .class)
    }
    
    func test_struct() {
        var user = UserStruct()
        test_keyValueCoding(&user, kind: .struct)
        
        // Existential
        var p: UserProtocol = user
        swift_setValue(777, to: &p, key: "id")
        XCTAssert(swift_value(of: &p, key: "id") as? Int == 777)
        
        var song: SongProtocol = Song(name: "")
        swift_setValue("Blue Suede Shoes", to: &song, key: "name")
        XCTAssert(swift_value(of: &song, key: "name") as? String == "Blue Suede Shoes")
    }
    
    func test_optional() {
        var optional: UserClass? = UserClass()
        optional?["id"] = 123
        
        XCTAssert(optional?["id"] as? Int == 123)
        XCTAssert(optional?.value(key: "id") as? Int == 123)
        
        XCTAssertNil(swift_value(of: &optional, key: "id"))
    }
    
    func test_fail() {
        var user = UserClass()
        
        // Set wrong type
        user["id"] = "Hello"
        user["name"] = 11
        user["type"] = nil
        user["array"] = ["1", "2"]
        user["info"] = "123"
        XCTAssert(user.id == 0)
        XCTAssertNil(user.name)
        XCTAssert(user.type == .none)
        XCTAssert(user.array.isEmpty == true)
        XCTAssert(user.info.phone.isEmpty && user.info.email.isEmpty)
    }
}
