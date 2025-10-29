use binaryninja::headless::Session;
use binaryninja::repository::RepositoryManager;

#[test]
fn test_list() {
    let _session = Session::new().expect("Failed to initialize session");
    let repositories = RepositoryManager::repositories();
    for repository in &repositories {
        let repo_path = repository.path();
        let repository_by_path = RepositoryManager::repository_by_path(&repo_path).unwrap();
        assert_eq!(repository.url(), repository_by_path.url());

        for plugin in &repository.plugins() {
            let plugin_path = plugin.path();
            let plugin_by_path = repository.plugin_by_path(&plugin_path).unwrap();
            assert_eq!(plugin.package_url(), plugin_by_path.package_url());
        }
    }
}
