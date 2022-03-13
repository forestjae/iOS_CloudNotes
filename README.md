## iOS 커리어 스타터 캠프

# STEP1
## 0. 구현내용

- SplitViewController를 사용한 화면 구현
    - 좌측 PrimaryView : TableViewController, 메모의 리스트를 dataSource로 정보 표현
    - 우측 SecondaryView : TextView를 사용하여 개별 메모를 dataSource로 정보 표현
- SplitViewController가 `NoteDataSource` 프로토콜을 채택한 `JSONDataSourceProvider` 타입의 객체를 소유하고 있으며, 해당 객체를 이용하여 DataSource의 저장과 매니징을 할 수 있음
- PrimaryView의 메모 리스트에서 메모를 선택하면 SecondaryView에 상세 메모가 보여지고, 수정 가능
- SecondaryView에서의 메모 수정은 PirmaryView의 메모리스트에도 실시간으로 영향을 미치도록 구현
- 기타 요구사항에 명시되어있지 않은 상세 구현부분은 iPadOS기본 메모앱을 참고하여 진행했습니다.

## 1. 고민했던 점

### 1. DataSourceProvider를 위한 Protocol

- 이후 적용될 CoreData에 대응하기 위해 JSONData 외의 타입도 포괄하는 Protocol을 구현하였습니다.
    - 향후 기능 업데이트에 따라 `delete()` , `search()`, `save()`등이 추가될 예정입니다.

### 2. 지역에 따른 날짜의 포맷 변경

- 사용자의 첫 번째 `PreferredLanguage`를 토대로 지역화를 진행했습니다.
    - 사용자에게 익숙한 문화권의 양식을 제공한다는 점에 의의가 있다고 판단하였습니다.
    - `Current`로 언어 설정을 가져올 경우, 앱 설정의 언어 환경을 가져오는 점을 확인했습니다.

### 3. TextView의 Text를 메모 객체로 변환하는 방법

- 텍스트 뷰가 수정되었을 때 실시간으로 PrimaryVC에도 반영하기 위해서 아래와 같이 TextViewDelegate메서드를 사용하여 구현하였습니다.
- 제목과 내용을 분리하는 기준을 줄바꿈이 있을 경우 줄바꿈으로 구분, 그 외의 경우는 제목 100자까지로 제한하였습니다.

```swift
func textViewDidChange(_ textView: UITextView) {
        var content = textView.text.components(separatedBy: ["\n"])
        var title = content.removeFirst()
        var body = content.joined(separator: "")

        if title.count > 100 {
            title = String(textView.text.prefix(100))
            body = String(textView.text.suffix(textView.text.count - 100))
        }

        let modifiedDate = Date().timeIntervalSince1970
        let newNote = Note(title: title, body: body, lastModifiedDate: modifiedDate)
				...
    }
```

---

## 2. 해결이 되지 않은 점

### 1. TextView의 AttributedText 설정

- TextView에서 제목에 해당하는 부분의 폰트를 부분적으로 변경해 주기 위해 `AttributedText` 프로퍼티와 `NSMutableAttributedString` 클래스를 사용하여 구현하였습니다. 다만 메모가 실시간으로 수정되어도 해당 설정이 유지되도록 구현하고자 하였는데, 내용 수정 후 AttributedText의 값을 다시 업데이트 해주는 과정에서 커서가 내용의 끝으로 이동하는 현상이 발생하는 것을 확인할 수 있었습니다.  이 상황에 대응하려면 AttributedText프로퍼티에 새로운 값을 주입하는 방식이 아닌 다른 방식을 사용해야 될 것 같다고 생각이 되는데 방법을 찾지 못했습니다.
    - 참고 이미지
    
    ![스크린샷 2022-02-09 오후 10.27.05.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a945918b-47f8-4e11-8d58-e7731a1d4a76/스크린샷_2022-02-09_오후_10.27.05.png)
    

### 2. 하단의 내용을 상단으로 스크롤하는 기능

- 기본 메모앱의 경우, 사용의 쾌적한 편집환경을 위해서 TextView의 Bottom Inset을 주어 편집 시 커서가 있는 부분을 상단으로 스크롤 할 수 있도록 구현되있는 것을 확인했습니다.
- TextView 자체의 ScrollView를 활용하는 상황에서는 어떤 방식으로 Inset을 부여해도 의도한 대로 동작하지 않아 별도의 `ScrollView` 내부에 TextView를 하위뷰로 넣는 방식으로 고민해 보았는데요. 해당 방법을 선택했을 시 줄바꿈 스크롤 대응을 별도로 구현해 줘야 한다는 단점이 있었습니다. 좀 더 좋은 방법을 고민해 보고 있습니다.

---

## 3. 조언을 얻고 싶은 부분

### 1. VC간 데이터 전달 방식

- 부모VC → 자식VC의 경우는 `프로퍼티 직접 주입`, 자식VC→ 부모VC의 경우는 `NotificationCenter`를 사용하였습니다.
    - SplitVC가 PrimaryVC와 SecondaryVC를 알고있기 때문에, 프로퍼티를 직접 주입하는 방식을 택했습니다.
    - PrimaryVC와 SecondaryVC에서 필요한 DataSource를 특정하기 위해 `IndexPath`를 전달해야 했는데 이때 NotificationCenter를 활용하여 전달 해 주었습니다.
- 처음 구현을 할때는, 다수의 객체들에 동시에 이벤트를 송신할 일이 있을수도 있다고 생각하여 `NotificationCenter`를 사용하였는데요 구현을 하고 나니 단일 객체에만 이벤트를 보내고 있어서 Delegate패턴을 사용해도 괜찮을 것 같다는 생각이 들었습니다. 이런 경우에는 `Delegate`패턴을 사용하는 게 더 좋은 선택일까요?

> 알게 된 내용: NotificationCenter의 이용은 앱의 로직을 불분명하고 복잡하게 만들 수 있다. 위와 같은 케이스처럼 단일객체에 이벤트를 보내는 경우는 Delegate Pattern을 사용하는것이 여러모로 우위에 있다.

# STEP2

## 0. 구현내용

- [x]  CoreData CRUD를 구현한 `PersistentManager` 타입 구현
- [x]  `PersistentManager`의 메서드를 활용하여 `CDDataSourceProvider` 구현
- [x]  우측 Secondary View가 보여주고 있는 노트에 따라 Primary View의 셀 선택 구현
    - 선택 된 셀 삭제 시 바로 밑의 셀로 선택 이동 및 해당 셀의 노트 내용 표시
- [x]  노트의 수정에 따라 노트 리스트와 원본데이터 실시간으로 변경
- [x]  셀 스와이프 시 공유 / 삭제 기능 구현
- [x]  우측 상단 더보기 버튼 터치 시 공유 / 삭제 기능 구현
- [x]  공유 기능은 Popover 형태로 구현

## 1. 고민했던 점

### 1. NSManagedObjectContext를 전역으로 관리하는 이유

- context를 `self.context`로 각각의 메서드에서 호출할 때마다 별도의 context가 생성됩니다.
    - 이 경우, sync가 어려워진다는 문제가 생길 수 있어 전역으로 생성해주었습니다.

### 2. 프로토콜 채택 유지를 위한 JSONDSProvider의 빈 메서드

- `JSONDataSourceProvider`와 `CDDataSourceProvider`가 동시에 `NoteDataSource` 프로토콜을 채택합니다.
    - `CDDataSourceProvider`는 fetch() 이외에도 `CRUD` 메서드를 가지고 있습니다.
    - SplitVC가 Provider를 프로토콜로 가지기 위해 `JSONDataSourceProvider`의 CRUD 메서드는 비어있게 작성하였습니다.

### 3. BarButtonItem의 popover 위치 설정

- activityVC의 popover 위치를 sender로 잡아주기 위해 아래와 같이 추가 설정을 하였습니다.
    
    코드 1-3-1
    
    ```swift
    activityController.popoverPresentationController?.barButtonItem = actionButton
    ```
    

### 4. ActivityVC 에러핸들링

- activityVC를 두 번 이상 생성하고 dismiss했을 때 런타임 에러가 발생하였습니다.
    - 코드 2-3-1의 옵션은, 한 번 호출된 이후 nil값을 반환하기 때문에 `activityController`의 호출부에 매번 설정하도록 수정하여 에러를 해결했습니다.

---

## 2. 해결이 되지 않은 점

### 2-1. insertRows, reloadRows 사용 시 크래시 발생

- 셀 추가 시 애니메이션 작동을 위하여 아래와 같이 코드를 작성하였는데, 현재 list의 row가 존재 하지 않을때 추가를 해주게 되면 invalid update오류가 발생합니다.

```swift
if noteListData.count == 0 {
		self.noteListData.append(note)
		self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
} else {
		self.noteListData.insert(note, at: 0)
		self.tableView.insertRows(at: [firstIndex], with: .automatic)
}
```

---

## 3. 조언을 얻고 싶은 부분

### 3-1. 테이블 뷰 셀에 선택된 노트와 상세 노트뷰에 표현되는 노트의 일치화

위와 같은 구현을 위해 현재 상세보기 중인 노트의 `indexPath`를 저장하는 전역변수와, 테이블 뷰에서 선택된 셀의 `indexPath`를 저장하는 전역변수, 그 외 서로 데이터를 주고 받는 메서드가 생기게 되어 가독성이 안 좋아진 것 같습니다. 😭 찰리라면 어떤식으로 구현하셨을지 궁금합니다!

---

# STEP3

## 0. 구현내용

- [ ]  SwfityDropbox라이브리러리 사용을 통한 메모 업로드 및 불러오기 기능 구현(최종 백업시간 표시)
- [ ]  DropBox 로그인 상태에 따른 액션시트 구현 (로그인/ 로그아웃 기능)
- [ ]  타이머를 사용한 자동 업로드 (주기: 15초)
- [ ]  멀티태스킹 중, 리스트의 메모를 선택시 편집 화면 제공

---

## 고민했던 점

### 1. 동기화 방식

- 공유 버튼 제공을 통해 사용자가 수동 백업을 진행할 수 있도록 기능을 제공하였습니다.
- Timer를 활용하여 일정 주기마다 자동으로 백업이 진행, 사용자가 원할 때 다운로드가 가능하도록 구현하였습니다.

### 2. DropboxManager 타입

- DropboxManager의 client변수가 SwiftyDropbox의 `DropboxClientsManager.authorizedClient` 변수를 참조하기 때문에 Class로 설계하였습니다.

### 3. 타이머의 발동 조건

DropboxManager에 client 변수를 생성해 해당 client의 값이 변경될때 검증하고 Noti를 보내어 타이머의 트리거로 활용하려했습니다. 그러나 `DropboxClientsManager.authorizedClient` 라는 라이브리러의 타입 프로퍼티를 참조하는 client값을 추적하는 property observer가 제대로 동작하지 않는 문제가 있어 해당 구현은 포기하였습니다. 

```swift
var client = DropboxClientsManager.authorizedClient {
        willSet {
            print("감시자 잘 작동하고 있음 \(newValue)")
            NotificationCenter.default.post(
                name: NSNotification.Name("ClientStatusChanged"),
                object: newValue == nil ? false : true
            )
        }
    }
```

위 구문과 비슷하게 Playground에서 테스트 코드로 실험해 본 결과, 다른 참조타입을 참조하고 있는 변수도 프로퍼티 감시자가 제대로 작동하던데, 위 구문에서 작동하지 않는 이유를 파악하지 못했습니다.

> 알아낸 점 : 참조타입을 client변수에 주입했기 때문에, 해당 client의 값이 변경되더라도 연결된 참조가 변경되는 것이 아니기에 추적이 불가능한 것

# STEP4 

## 0. 구현내용

- [ ]  전반적인 코드 컨벤션과 스타일을 통일하는 방향으로 리팩토링 진행하였습니다.
- [ ]  SearchController를 사용하여 List VC에 검색기능 구현
- [ ]  검색된 내용을 클릭하면 Detail VC에 메모 상세가 나오도록 구현
    - [ ]  메모 상세가 나온 상태에서 검색을 취소하여도 적절한 인덱스의 셀이 선택되도록 구현

---

## 1. 고민했던 점

### 1. NoteListVC에서 SearchResultVC로 데이터 전달 방법

- 전자에서 검색된 데이터를 후자의 searchednoteData에 주입하기 위한 방법을 고민하였습니다.
- NoteList VC의 tableView에서 이미 property로 SearchResult VC를 갖고 있기 때문에, delegate 패턴 사용보다 타입 캐스팅이 자연스럽다고 판단하였습니다.

### 2. SearchResultVC의 Cell 선택

- 검색된 내용을 클릭하면 DetailVC에 메모 상세가 나오기 위해 SearchedResultVC의 delegate을 NoteListVC로 설정해주었습니다.
    - 이때 기존의 indexPath를 그대로 전달할 수 없어 어떤 `tableView` 인지에 따라 분기 처리를 하였습니다.
    - SearchResultVC의 tableView인 경우 , for where를 사용해 검색된 노트의 UUID를 활용하여  List VC에서 해당 노트의 IndexPath를 찾아내는 과정을 구현하였습니다.
    - 이때 선택된 IndexPath의 노트 데이터를 Detail VC로 보내는 과정은 기존의 로직을 재사용했습니다.
