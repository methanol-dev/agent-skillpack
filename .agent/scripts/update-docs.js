const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '../..');
const agentDir = path.join(rootDir, '.agent');

function countItems() {
  const skillsDir = path.join(agentDir, 'skills');
  const workflowsDir = path.join(agentDir, 'workflows');
  const rulesDir = path.join(agentDir, 'rules');
  const sharedDir = path.join(agentDir, '.shared');
  const agentsDir = path.join(agentDir, 'agents');

  const skillsCount = fs.existsSync(skillsDir)
    ? fs.readdirSync(skillsDir).filter(f => fs.statSync(path.join(skillsDir, f)).isDirectory()).length
    : 0;

  const workflowsCount = fs.existsSync(workflowsDir)
    ? fs.readdirSync(workflowsDir).filter(f => f.endsWith('.md')).length
    : 0;

  const rulesCount = fs.existsSync(rulesDir)
    ? fs.readdirSync(rulesDir).filter(f => f.endsWith('.md')).length
    : 0;

  const sharedCount = fs.existsSync(sharedDir)
    ? fs.readdirSync(sharedDir).filter(f => fs.statSync(path.join(sharedDir, f)).isDirectory()).length
    : 0;

  const agentsCount = fs.existsSync(agentsDir)
    ? fs.readdirSync(agentsDir).filter(f => f.endsWith('.md')).length
    : 0;

  console.log('==============================================');
  console.log('       ANTIGRAVITY DOCUMENTATION SYNC        ');
  console.log('==============================================');
  console.log(`📦 Skills:       ${skillsCount} bộ kỹ năng`);
  console.log(`⚡ Workflows:    ${workflowsCount} quy trình`);
  console.log(`🛡️ Rules:        ${rulesCount} rào chắn / nguyên tắc`);
  console.log(`🧬 Shared DNA:   ${sharedCount} module chia sẻ`);
  console.log(`🤖 Agents:       ${agentsCount} chuyên gia định danh`);
  console.log('==============================================');

  return {
    skillsCount,
    workflowsCount,
    rulesCount,
    sharedCount,
    agentsCount
  };
}

if (require.main === module) {
  countItems();
}

module.exports = { countItems };
