import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyGroupsView: View {
    @State private var groups: [Group] = []
    @State private var listener: ListenerRegistration?
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingCreateGroup = false
    @State private var showJoinGroupView = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                // Header with "My Groups" and Join Group button
                HStack {
                    Text("My Groups")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showJoinGroupView = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                    }
                    .sheet(isPresented: $showJoinGroupView) {
                        JoinGroupView()
                    }
                }
                .padding([.horizontal, .top])

                // Groups List
                List(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        HStack {
                            // Group Image
                            if let imageURL = group.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                            .cornerRadius(25)
                                    } else if phase.error != nil {
                                        // Error loading image
                                        Circle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.white)
                                            )
                                    } else {
                                        // Placeholder while loading
                                        ProgressView()
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            } else {
                                // No image URL, show placeholder
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Group Name and Description
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text(group.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Create New Group Button at Bottom
                Button(action: {
                    showingCreateGroup = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("Create a new group")
                            .font(.headline)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
                .sheet(isPresented: $showingCreateGroup) {
                    CreateGroupView()
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: startListening)
            .onDisappear(perform: stopListening)
            .alert(isPresented: $showingError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Functions

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated."
            showingError = true
            print("[startListening] No authenticated user found.")
            return
        }

        print("[startListening] Authenticated user ID: \(userId)")

        // Listen to 'members' documents where the 'userId' field == authenticated user ID
        listener = db.collectionGroup("members")
            .whereField("userId", isEqualTo: userId) // Adjusted query to check userId field
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    showingError = true
                    print("[startListening] Error fetching groups: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("[startListening] No groups found.")
                    self.groups = []
                    return
                }

                print("[startListening] Fetched members documents:")
                for doc in documents {
                    print("\tDocument Path: \(doc.reference.path)")
                }

                // Extract group references from member documents
                let groupRefs = documents.compactMap { $0.reference.parent.parent }

                print("[startListening] Extracted Group References:")
                for ref in groupRefs {
                    print("\tGroup Reference Path: \(ref.path)")
                }

                if groupRefs.isEmpty {
                    print("[startListening] No group references found.")
                    self.groups = []
                    return
                }

                // Fetch all group documents
                db.getAllDocuments(refs: groupRefs) { fetchedGroups, fetchError in
                    if let fetchError = fetchError {
                        errorMessage = "Failed to fetch group details: \(fetchError.localizedDescription)"
                        showingError = true
                        print("[startListening] Error fetching group details: \(fetchError.localizedDescription)")
                        return
                    }

                    guard let fetchedGroups = fetchedGroups else {
                        print("[startListening] No groups fetched.")
                        self.groups = []
                        return
                    }

                    print("[startListening] Fetched groups data:")
                    for groupDoc in fetchedGroups {
                        print("\tGroup ID: \(groupDoc.documentID), Data: \(groupDoc.data())")
                    }

                    // Convert Firestore documents to Group objects
                    DispatchQueue.main.async {
                        self.groups = fetchedGroups.compactMap { doc in
                            guard let data = doc.data() else {
                                print("[startListening] No data for document ID: \(doc.documentID)")
                                return nil
                            }
                            return Group(document: data, id: doc.documentID)
                        }
                        print("[startListening] Successfully updated groups array with \(self.groups.count) groups.")
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        print("[stopListening] Removed Firestore listener.")
    }

    // MARK: - Clipboard Functionality

    func shortGroupID(_ id: String) -> String {
        return String(id.prefix(8))
    }
}
