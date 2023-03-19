import controlP5.*;
import javax.swing.JOptionPane;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.net.URL;
import java.net.URLConnection;
import java.io.File;
import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import javax.swing.SwingUtilities;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JProgressBar;
import org.json.JSONArray;
import org.json.JSONObject;

ControlP5 cp5;

String VersionTag;
String VersionFile;
//modify to include valid owner,repo & zip name
String owner = "repo owner name";
String repo = "repo-name";
String fileName = "zip file name.zip";
//change directiory of zip download and zip extraction currently update folder is used!
String saveDir = System.getProperty("user.dir") + "/update";
String destinationFolderPath =  System.getProperty("user.dir") + "/update";
String appPath = System.getProperty("user.dir");
File folder = new File(appPath);
File[] listOfFiles = folder.listFiles();
File versionFile = null;
String releaseUrl = String.format("https://api.github.com/repos/%s/%s/releases/latest", owner, repo);
JSONObject latestRelease = getLatestRelease(releaseUrl);
String downloadUrl = getDownloadUrl(latestRelease, fileName);
JSONObject getLatestRelease(String url) {
  try {
    // Use personal token for more requests for testing 5k/hour,60/hour without token
    // String authToken = "github_pat_"; // replace with your PAT
    URL apiLink = new URL(url);
    URLConnection conn = apiLink.openConnection();
    conn.setRequestProperty("Accept", "application/vnd.github.v3+json");
    conn.setRequestProperty("User-Agent", "Java");
    //uncomment to use token
    //conn.setRequestProperty("Authorization", "token " + authToken); // set the authorization header with your PAT
    BufferedInputStream in = new BufferedInputStream(conn.getInputStream());
    byte[] dataBuffer = new byte[1024];
    int bytesRead;
    StringBuilder responseBuilder = new StringBuilder();
    while ((bytesRead = in.read(dataBuffer, 0, 1024)) != -1) {
      responseBuilder.append(new String(dataBuffer, 0, bytesRead));
    }
    in.close();
    return new JSONObject(responseBuilder.toString());
  }
  catch (Exception e) {
    System.err.println("Error: " + e.getMessage());
    return null;
  }
}

String getDownloadUrl(JSONObject release, String fileName) {
  JSONArray assets = release.getJSONArray("assets");
  for (int i = 0; i < assets.length(); i++) {
    JSONObject asset = assets.getJSONObject(i);
    if (asset.getString("name").equals(fileName)) {
      return asset.getString("browser_download_url");
    }
  }
  return null;
}

void setup() {

  size(150, 150);

  ControlP5 cp5 = new ControlP5(this);

  cp5.addButton("Update")
    .setPosition(50, 60)
    .setSize(50, 25);
}

void draw()
{
  background(0);
}

void Update()
{
  checkLocalVersion();

  checkForUpdates();
}
void checkLocalVersion()
{
//function looks for file in the working directory with v(number.number) in its name
  for (int i = 0; i < listOfFiles.length; i++) {
    if (listOfFiles[i].isFile()) {
      String fileName = listOfFiles[i].getName();
      if (fileName.matches(".*v\\d+\\.\\d+.*")) {
        VersionTag = fileName.replaceAll(".*(v\\d+\\.\\d+).*", "$1");
        versionFile = listOfFiles[i];
        break;
      }
    }
  }
  System.out.println("VersionTag: " + VersionTag);
}



void checkForUpdates() {
  Object[] options = {"Yes", "No"};
  int result = JOptionPane.showOptionDialog(null, "Check for updates?", "Check for Updates",
    JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE, null, options, options[0]);
  if (result == JOptionPane.YES_OPTION) {
    println("Yes, check for updates");
    getLatestRelease();
    checkReleaseVersion();
  } else {
    println("No, don't check for updates");
  }
}

void downloadLatestRelease(String downloadUrl, String saveDir, String fileName, String destinationFolderPath) {
  try {
    URL url = new URL(downloadUrl);
    URLConnection conn = url.openConnection();
    conn.connect();
    int contentLength = conn.getContentLength();
    BufferedInputStream in = new BufferedInputStream(conn.getInputStream());
    FileOutputStream out = new FileOutputStream(saveDir + fileName);
    BufferedOutputStream bout = new BufferedOutputStream(out, 1024);
    byte[] data = new byte[1024];
    int x = 0;
    int bytesRead = 0;

    // Create progress bar
    JProgressBar progressBar = new JProgressBar();
    progressBar.setStringPainted(true);

    // Create dialog to show progress bar
    JDialog dialog = new JDialog();
    dialog.add(progressBar);
    dialog.setTitle("Downloading update...");
    dialog.setSize(300, 75);
    dialog.setLocationRelativeTo(null);
    dialog.setVisible(true);

    while ((bytesRead = in.read(data, 0, 1024)) >= 0) {
      bout.write(data, 0, bytesRead);
      x += bytesRead;
      int percentCompleted = (int) ((x / (float) contentLength) * 100);

      // Update progress bar
      SwingUtilities.invokeLater(new Runnable() {
        public void run() {
          progressBar.setValue(percentCompleted);
        }
      }
      );
    }
    bout.close();
    in.close();
    extractZipFile(saveDir + fileName, destinationFolderPath);
    dialog.dispose(); // Close progress bar dialog
    String restartMessage = "The app has been updated to " + latestRelease.getString("tag_name") + ". Please restart //appname//.";
    JOptionPane.showMessageDialog(null, restartMessage, "Update", JOptionPane.INFORMATION_MESSAGE);
    if (versionFile != null) { // check the flag value before deleting the version file
      boolean deleted = versionFile.delete();
      if (deleted) {
        System.out.println("Deleted version file: " + versionFile.getName());
        exit();
      } else {
        System.out.println("Failed to delete version file: " + versionFile.getName());
      }
    }
  }
  catch (IOException e) {
    System.err.println("Error: " + e.getMessage());
  }
}

void checkReleaseVersion() {

  if (latestRelease == null) {
    System.out.println("Unable to retrieve latest release information.");
    return;
  }
  if (VersionTag == null)
  {
    String message = "Unable to retrieve local app information";
    JOptionPane.showMessageDialog(null, message, "Update", JOptionPane.INFORMATION_MESSAGE);
    return;
  }

  String latestTag = latestRelease.getString("tag_name");
  if (latestTag.equals(VersionTag)) {
    String message = "No need to update, you are using the latest " + latestTag + "  of  //appname//.";
    JOptionPane.showMessageDialog(null, message, "Update", JOptionPane.INFORMATION_MESSAGE);
  } else {
    Object[] options = {"Update", "Cancel"};
    int result = JOptionPane.showOptionDialog(null, "A new version of  //appname// is available. Do you want to update?", "Update Available",
      JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE, null, options, options[0]);
    if (result == JOptionPane.YES_OPTION) {
      downloadLatestRelease(downloadUrl, saveDir, fileName, destinationFolderPath);
    }
  }
}


void getLatestRelease()
{
  System.out.println("Latest release tag: " + latestRelease.getString("tag_name"));
}


void extractZipFile(String zipFilePath, String destinationFolderPath) {
  try {
    ZipInputStream zipInputStream = new ZipInputStream(new FileInputStream(zipFilePath));
    ZipEntry zipEntry = zipInputStream.getNextEntry();
    byte[] buffer = new byte[1024];

    while (zipEntry != null) {
      String fileName = zipEntry.getName();
      File newFile = new File(destinationFolderPath + fileName);
      System.out.println("Extracting file: " + newFile.getAbsolutePath());

      if (zipEntry.isDirectory()) {
        // Create the directory
        newFile.mkdirs();
      } else {
        // Create all non-existing parent directories
        new File(newFile.getParent()).mkdirs();

        // Write the file contents
        FileOutputStream fos = new FileOutputStream(newFile);
        int len;
        while ((len = zipInputStream.read(buffer)) > 0) {
          fos.write(buffer, 0, len);
        }
        fos.close();
      }

      zipEntry = zipInputStream.getNextEntry();
    }

    zipInputStream.closeEntry();
    zipInputStream.close();

    System.out.println("Zip file extracted to: " + destinationFolderPath);

    // Delete the zip file
    File zipFile = new File(zipFilePath);
    if (zipFile.delete()) {
      System.out.println("Zip file deleted successfully");
    } else {
      System.err.println("Failed to delete zip file");
    }
  }
  catch (IOException e) {
    System.err.println("Error extracting zip file: " + e.getMessage());
  }
}
