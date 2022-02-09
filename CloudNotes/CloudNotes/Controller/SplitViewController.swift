import UIKit

class SplitViewController: UISplitViewController {
    let noteListViewController = NoteListViewController()
    let detailedNoteViewController = DetailedNoteViewController()
    var dataSourceProvider: NoteDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSourceProvider = JSONDataSourceProvider()
        self.preferredDisplayMode = .oneBesideSecondary
        self.preferredSplitBehavior = .tile
        self.setViewController(noteListViewController, for: .primary)
        self.setViewController(detailedNoteViewController, for: .secondary)
        fetchNotes()
        configurePostNotification()
    }

    func fetchNotes() {
        do {
            try dataSourceProvider?.fetch()
        } catch {
            print(error.localizedDescription)
        }

        guard let data = dataSourceProvider?.noteList else {
            return
        }

        noteListViewController.noteData = data
    }

    // MARK: - Configure Notification

    func configurePostNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(passNote(notification:)),
                                               name: NSNotification.Name("NoteListSelected"),
                                               object: nil)
    }

    @objc
    func passNote(notification: Notification) {
        guard let index = notification.object as? Int else {
            return
        }

        detailedNoteViewController.noteData = dataSourceProvider?.noteList[index]
    }
}