const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '..', 'lib');

function getAllFiles(dirPath, arrayOfFiles) {
  const files = fs.readdirSync(dirPath);
  arrayOfFiles = arrayOfFiles || [];

  files.forEach(function(file) {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      arrayOfFiles = getAllFiles(fullPath, arrayOfFiles);
    } else if (file.endsWith('.dart')) {
      arrayOfFiles.push(fullPath);
    }
  });

  return arrayOfFiles;
}

const dartFiles = getAllFiles(libDir);

dartFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');

  // Fix imports that incorrectly targeted package:tradingpro/features/...
  content = content.replace(/package:tradingpro\/features\/(core|models|providers|repositories|router|services|shared_widgets)\//g, 'package:tradingpro/$1/');
  content = content.replace(/package:tradingpro\/features\/admin\/(core|models|providers|repositories|router|services|shared_widgets)\//g, 'package:tradingpro/$1/');

  // Fix any relative imports to top-level folders
  content = content.replace(/import\s+['"](?:\.\.\/)+((?:core|features|models|providers|repositories|router|services|shared_widgets)\/[^'"]+)['"]/g, "import 'package:tradingpro/$1'");

  // Fix same-folder relative imports in core/theme
  if (file.includes('core\\theme') || file.includes('core/theme')) {
    content = content.replace(/import\s+['"](app_colors\.dart|app_text_styles\.dart|app_theme\.dart)['"]/g, "import 'package:tradingpro/core/theme/$1'");
  }

  fs.writeFileSync(file, content, 'utf8');
});

console.log(`Cleaned up imports across ${dartFiles.length} files.`);
